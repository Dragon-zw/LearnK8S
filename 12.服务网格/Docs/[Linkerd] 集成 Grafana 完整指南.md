# Linkerd 集成 Grafana 完整指南

## 背景说明

从 Linkerd 2.12 版本开始，**Linkerd Viz 不再内置 Grafana**，需要用户自行部署并集成。

本指南提供完整的 Grafana 集成方案，解决 Dashboard 下载失败问题。

## 问题分析

### 原始问题

使用 `gnetId` 从 Grafana.com 下载 Dashboard 时出现 EOF 错误：

```
logger=provisioning.dashboard type=file name=default level=error 
msg="failed to load dashboard from" file=/var/lib/grafana/dashboards/default/top-line.json error=EOF
```

### 根本原因

1. **网络问题**: 无法访问 grafana.com
2. **Dashboard 版本**: ID 或 revision 不正确
3. **依赖外部服务**: 不稳定且不可靠

## 解决方案

### 方案概述

使用 Linkerd 官方提供的 Dashboard JSON 文件，通过 ConfigMap 挂载到 Grafana。

**优势**:
- ✅ 无需网络下载
- ✅ 使用官方 Dashboard
- ✅ 稳定可靠
- ✅ 版本匹配

## 安装步骤

### 方法 1: 使用自动化脚本（推荐）

```bash
cd /root/LearnK8S/12.服务网格/Manifest/1.Linkerd\ 安装部署/

# 运行安装脚本
./install-grafana.sh
```

脚本会自动完成：
1. 下载 Linkerd Dashboard JSON 文件
2. 创建 Dashboard ConfigMap
3. 部署 Grafana
4. 验证安装

### 方法 2: 手动安装

#### 步骤 1: 下载 Linkerd Dashboard 文件

```bash
# 克隆 Linkerd 仓库
cd /tmp
git clone --depth 1 https://github.com/linkerd/linkerd2.git

# 查看 Dashboard 文件
ls -la /tmp/linkerd2/grafana/dashboards/
```

**包含的 Dashboard**:
- `top-line.json` - 顶层指标
- `health.json` - 健康状态
- `deployment.json` - Deployment 指标
- `pod.json` - Pod 指标
- `service.json` - Service 指标
- `namespace.json` - Namespace 指标
- 等等...

#### 步骤 2: 创建 Dashboard ConfigMap

```bash
kubectl create configmap linkerd-grafana-dashboards \
    -n linkerd-viz \
    --from-file=/tmp/linkerd2/grafana/dashboards/ \
    --dry-run=client -o yaml | kubectl apply -f -
```

验证 ConfigMap:
```bash
kubectl get configmap -n linkerd-viz linkerd-grafana-dashboards
kubectl describe configmap -n linkerd-viz linkerd-grafana-dashboards
```

#### 步骤 3: 准备 Grafana Values 文件

使用修复后的配置文件 `values-fixed.yaml`:

```yaml
podAnnotations:
  linkerd.io/inject: enabled

grafana.ini:
  server:
    root_url: "%(protocol)s://%(domain)s:/grafana/"
  auth:
    disable_login_form: true
  auth.anonymous:
    enabled: true
    org_role: Editor

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: prometheus
        type: prometheus
        url: http://prometheus.linkerd-viz.svc.cluster.local:9090
        isDefault: true

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
      - name: "linkerd"
        orgId: 1
        folder: "Linkerd"
        type: file
        options:
          path: /var/lib/grafana/dashboards/linkerd

# 关键配置：使用 ConfigMap 而不是 gnetId
dashboardsConfigMaps:
  linkerd: "linkerd-grafana-dashboards"
```

#### 步骤 4: 部署 Grafana

```bash
# 添加 Grafana Helm 仓库
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 部署 Grafana
helm upgrade --install grafana \
    -n linkerd-viz \
    grafana/grafana \
    -f values-fixed.yaml \
    --wait
```

#### 步骤 5: 验证安装

```bash
# 检查 Pod 状态
kubectl get pods -n linkerd-viz -l app.kubernetes.io/name=grafana

# 检查日志（不应该有 EOF 错误）
kubectl logs -n linkerd-viz -l app.kubernetes.io/name=grafana --tail=50

# 验证 Dashboard 挂载
kubectl exec -n linkerd-viz -it \
    $(kubectl get pod -n linkerd-viz -l app.kubernetes.io/name=grafana -o name) \
    -- ls -la /var/lib/grafana/dashboards/linkerd/
```

## 访问 Grafana

### 方法 1: Port Forward

```bash
kubectl port-forward -n linkerd-viz svc/grafana 3000:80
```

然后访问: http://localhost:3000

### 方法 2: 创建 Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: linkerd-viz
spec:
  ingressClassName: nginx
  rules:
    - host: linkerd-grafana.qikqiak.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 80
```

### 获取登录密码

```bash
kubectl get secret -n linkerd-viz grafana \
    -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

默认用户名: `admin`

## 配置 Linkerd Viz 使用 Grafana

更新 Linkerd Viz 配置，指向你的 Grafana：

```bash
# 方法 1: 重新安装 Viz 并指定 Grafana URL
linkerd viz install \
    --set grafana.url=grafana.linkerd-viz.svc.cluster.local:80 \
    | kubectl apply -f -

# 方法 2: 修改现有配置
kubectl edit configmap -n linkerd-viz linkerd-viz-config
# 添加或修改: grafana: grafana.linkerd-viz.svc.cluster.local:80
```

## 故障排查

### 问题 1: Dashboard 仍然显示 EOF 错误

**检查**:
```bash
kubectl logs -n linkerd-viz -l app.kubernetes.io/name=grafana | grep -i error
```

**解决**:
- 确认 ConfigMap 已创建: `kubectl get cm -n linkerd-viz linkerd-grafana-dashboards`
- 确认 values 文件使用 `dashboardsConfigMaps` 而不是 `gnetId`
- 重新部署 Grafana

### 问题 2: Dashboard 文件夹为空

**检查**:
```bash
kubectl exec -n linkerd-viz -it \
    $(kubectl get pod -n linkerd-viz -l app.kubernetes.io/name=grafana -o name) \
    -- ls /var/lib/grafana/dashboards/linkerd/
```

**解决**:
- 检查 ConfigMap 数据: `kubectl describe cm -n linkerd-viz linkerd-grafana-dashboards`
- 确认 `dashboardProviders` 配置正确
- 检查 Pod 挂载: `kubectl describe pod -n linkerd-viz -l app.kubernetes.io/name=grafana`

### 问题 3: Prometheus 数据源连接失败

**检查**:
```bash
# 验证 Prometheus 服务
kubectl get svc -n linkerd-viz prometheus

# 测试连接
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
    curl http://prometheus.linkerd-viz.svc.cluster.local:9090/api/v1/query?query=up
```

**解决**:
- 确认 Prometheus 正在运行
- 检查 Service 名称和端口
- 更新 datasources 配置中的 URL

## 配置文件对比

### ❌ 错误配置（使用 gnetId）

```yaml
dashboards:
  default:
    top-line:
      gnetId: 15474  # 会导致 EOF 错误
      revision: 3
      datasource: prometheus
```

### ✅ 正确配置（使用 ConfigMap）

```yaml
dashboardsConfigMaps:
  linkerd: "linkerd-grafana-dashboards"

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
      - name: "linkerd"
        folder: "Linkerd"
        type: file
        options:
          path: /var/lib/grafana/dashboards/linkerd
```

## 完整的 Dashboard 列表

Linkerd 官方提供的 Dashboard:

| Dashboard | 文件名 | 说明 |
|-----------|--------|------|
| Top Line | top-line.json | 顶层指标概览 |
| Health | health.json | 健康状态检查 |
| Kubernetes | kubernetes.json | Kubernetes 资源 |
| Namespace | namespace.json | 命名空间指标 |
| Deployment | deployment.json | Deployment 详情 |
| Pod | pod.json | Pod 级别指标 |
| Service | service.json | Service 指标 |
| Route | route.json | 路由指标 |
| Authority | authority.json | Authority 指标 |
| CronJob | cronjob.json | CronJob 指标 |
| Job | job.json | Job 指标 |
| DaemonSet | daemonset.json | DaemonSet 指标 |
| ReplicaSet | replicaset.json | ReplicaSet 指标 |
| StatefulSet | statefulset.json | StatefulSet 指标 |
| ReplicationController | replicationcontroller.json | RC 指标 |
| Prometheus | prometheus-2-stats.json | Prometheus 统计 |
| Prometheus Benchmark | prometheus-benchmark.json | 性能基准 |
| Multicluster | multicluster.json | 多集群指标 |

## 卸载

```bash
# 卸载 Grafana
helm uninstall -n linkerd-viz grafana

# 删除 ConfigMap
kubectl delete configmap -n linkerd-viz linkerd-grafana-dashboards

# 清理临时文件
rm -rf /tmp/linkerd2
```

## 参考资源

- [Linkerd Grafana 集成文档](https://linkerd.io/2.14/tasks/grafana/)
- [Linkerd Dashboard 源码](https://github.com/linkerd/linkerd2/tree/main/grafana/dashboards)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

---

**最后更新**: 2025-11-25
**适用版本**: Linkerd 2.12+
