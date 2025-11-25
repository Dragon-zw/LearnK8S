# Linkerd 2.11.1 版本安装教程

本教程详细介绍如何在 Kubernetes 集群中安装 Linkerd stable-2.11.1 版本。

## 前置要求

### 1. 环境要求
- Kubernetes 集群版本 >= 1.21
- kubectl 命令行工具已配置并可访问集群
- 集群节点有足够的资源（建议每个节点至少 2 CPU 和 4GB 内存）
- 能够访问互联网（用于拉取镜像）

### 2. 验证集群访问
```bash
# 检查 kubectl 版本和集群连接
kubectl version --short

# 检查集群节点状态
kubectl get nodes
```

## 安装步骤

### 步骤 1: 安装 Linkerd CLI 工具

> **重要提示**: 官方安装脚本 `https://run.linkerd.io/install` 默认会安装**最新稳定版本**，而不是 2.11.1。要安装 2.11.1 版本，请使用方法 1 或方法 2。

#### 方法 1: 下载指定版本（推荐用于安装 2.11.1）

**Linux 系统**:
```bash
# 下载 Linkerd 2.11.1 版本
curl -sLO https://github.com/linkerd/linkerd2/releases/download/stable-2.11.1/linkerd2-cli-stable-2.11.1-linux-amd64

# 添加执行权限
chmod +x linkerd2-cli-stable-2.11.1-linux-amd64

# 移动到系统路径
sudo mv linkerd2-cli-stable-2.11.1-linux-amd64 /usr/local/bin/linkerd

# 验证安装
linkerd version --client
```

**macOS 系统**:
```bash
# 下载 Linkerd 2.11.1 版本
curl -sLO https://github.com/linkerd/linkerd2/releases/download/stable-2.11.1/linkerd2-cli-stable-2.11.1-darwin-amd64

# 添加执行权限
chmod +x linkerd2-cli-stable-2.11.1-darwin-amd64

# 移动到系统路径
sudo mv linkerd2-cli-stable-2.11.1-darwin-amd64 /usr/local/bin/linkerd

# 验证安装
linkerd version --client
```

**macOS ARM (M1/M2) 系统**:
```bash
# 下载 Linkerd 2.11.1 版本
curl -sLO https://github.com/linkerd/linkerd2/releases/download/stable-2.11.1/linkerd2-cli-stable-2.11.1-darwin-arm64

# 添加执行权限
chmod +x linkerd2-cli-stable-2.11.1-darwin-arm64

# 移动到系统路径
sudo mv linkerd2-cli-stable-2.11.1-darwin-arm64 /usr/local/bin/linkerd

# 验证安装
linkerd version --client
```

#### 方法 2: 使用安装脚本指定版本

```bash
# 设置要安装的版本
export LINKERD2_VERSION=stable-2.11.1

# 下载并安装指定版本
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

# 将 Linkerd CLI 添加到 PATH
export PATH=$PATH:$HOME/.linkerd2/bin

# 将上面的 export 命令添加到 shell 配置文件中（永久生效）
echo 'export PATH=$PATH:$HOME/.linkerd2/bin' >> ~/.bashrc
source ~/.bashrc

# 验证安装的版本
linkerd version --client
```

#### 方法 3: 使用官方脚本安装最新版本（不推荐用于 2.11.1）

```bash
# 注意: 此方法会安装最新稳定版本，而不是 2.11.1
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

# 将 Linkerd CLI 添加到 PATH
export PATH=$PATH:$HOME/.linkerd2/bin

# 将上面的 export 命令添加到 shell 配置文件中（永久生效）
echo 'export PATH=$PATH:$HOME/.linkerd2/bin' >> ~/.bashrc
source ~/.bashrc
```

#### 方法 4: 使用 Homebrew (macOS)

```bash
# 注意: Homebrew 通常安装最新版本
brew install linkerd

# 如果需要安装旧版本，需要使用特定的 formula
# 但 2.11.1 可能没有专门的 formula，建议使用方法 1
```

### 步骤 2: 验证 CLI 安装

```bash
# 检查 Linkerd CLI 版本
linkerd version

# 预期输出：
# Client version: stable-2.11.1
# Server version: unavailable
```

> **注意**: 此时 Server version 显示 unavailable 是正常的，因为还没有安装控制平面。

### 步骤 3: 集群预检查

在安装 Linkerd 控制平面之前，运行预检查以确保集群配置正确：

```bash
linkerd check --pre
```

**预期输出示例**:
```
Linkerd core checks
===================

kubernetes-api
--------------
√ can initialize the client
√ can query the Kubernetes API

kubernetes-version
------------------
√ is running the minimum Kubernetes API version
√ is running the minimum kubectl version

pre-kubernetes-setup
--------------------
√ control plane namespace does not already exist
√ can create non-namespaced resources
√ can create ServiceAccounts
√ can create Services
√ can create Deployments
√ can create CronJobs
√ can create ConfigMaps
√ can create Secrets
√ can read Secrets
√ can read extension-apiserver-authentication configmap
√ no clock skew detected

Status check results are √
```

> **重要**: 如果预检查失败，请根据错误提示解决问题后再继续。

### 步骤 4: 安装 Linkerd 控制平面

#### 方法 1: 使用默认配置安装（推荐）

```bash
# 生成 Linkerd 控制平面的 YAML 清单并应用
linkerd install | kubectl apply -f -
```

这个命令会：
1. 生成包含所有 Linkerd 控制平面资源的 Kubernetes 清单
2. 创建 `linkerd` 命名空间
3. 部署以下核心组件：
   - `linkerd-destination`: 服务发现和路由策略
   - `linkerd-identity`: TLS 证书管理
   - `linkerd-proxy-injector`: 自动注入 sidecar 代理

#### 方法 2: 先生成清单文件，再手动应用

```bash
# 生成清单文件
linkerd install > linkerd-install.yaml

# 查看生成的清单（可选）
less linkerd-install.yaml

# 应用清单
kubectl apply -f linkerd-install.yaml
```

#### 方法 3: 使用 Helm 安装

```bash
# 添加 Linkerd Helm 仓库
helm repo add linkerd https://helm.linkerd.io/stable
helm repo update

# 生成证书（Helm 安装需要手动提供证书）
# 1. 生成信任锚证书（Trust Anchor）
step certificate create root.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca --no-password --insecure

# 2. 生成颁发者证书（Issuer Certificate）
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca --not-after 8760h --no-password --insecure \
  --ca ca.crt --ca-key ca.key

# 设置证书过期时间（一年后）
# Linux:
exp=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ")
# macOS:
exp=$(date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")

# 安装 Linkerd 控制平面
helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$exp \
  --namespace linkerd \
  --create-namespace \
  linkerd/linkerd2
```

> **注意**: Helm 安装方式需要安装 `step` 工具来生成证书。可以从 https://smallstep.com/docs/step-cli/installation 下载。

### 步骤 5: 等待控制平面就绪

```bash
# 查看 linkerd 命名空间中的 Pod 状态
kubectl get pods -n linkerd

# 等待所有 Pod 变为 Running 状态
kubectl wait --for=condition=ready pod --all -n linkerd --timeout=300s
```

**预期输出**:
```
NAME                                      READY   STATUS    RESTARTS   AGE
linkerd-destination-79d6fc496f-xxxxx      4/4     Running   0          2m
linkerd-identity-6b78ff444f-xxxxx         2/2     Running   0          2m
linkerd-proxy-injector-86f7f649dc-xxxxx   2/2     Running   0          2m
```

### 步骤 6: 验证控制平面安装

```bash
# 运行完整的健康检查
linkerd check
```

**预期输出**:
```
Linkerd core checks
===================

kubernetes-api
--------------
√ can initialize the client
√ can query the Kubernetes API

kubernetes-version
------------------
√ is running the minimum Kubernetes API version
√ is running the minimum kubectl version

linkerd-existence
-----------------
√ 'linkerd-config' config map exists
√ heartbeat ServiceAccount exist
√ control plane replica sets are ready
√ no unschedulable pods
√ control plane pods are ready
√ cluster networks contains all node podCIDRs

linkerd-config
--------------
√ control plane Namespace exists
√ control plane ClusterRoles exist
√ control plane ClusterRoleBindings exist
√ control plane ServiceAccounts exist
√ control plane CustomResourceDefinitions exist
√ control plane MutatingWebhookConfigurations exist
√ control plane ValidatingWebhookConfigurations exist

linkerd-identity
----------------
√ certificate config is valid
√ trust anchors are using supported crypto algorithm
√ trust anchors are within their validity period
√ trust anchors are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust anchor

Status check results are √
```

### 步骤 7: 验证版本信息

```bash
# 检查客户端和服务端版本
linkerd version
```

**预期输出**:
```
Client version: stable-2.11.1
Server version: stable-2.11.1
```

## 安装可视化组件（Linkerd Viz）

Linkerd Viz 提供了 Dashboard、Grafana、Prometheus 等可观测性工具。

### 安装 Viz 插件

```bash
# 安装 Linkerd Viz 扩展
linkerd viz install | kubectl apply -f -
```

### 等待 Viz 组件就绪

```bash
# 查看 linkerd-viz 命名空间中的 Pod
kubectl get pods -n linkerd-viz

# 等待所有 Pod 就绪
kubectl wait --for=condition=ready pod --all -n linkerd-viz --timeout=300s
```

**预期输出**:
```
NAME                            READY   STATUS    RESTARTS   AGE
grafana-xxxxxxxxx-xxxxx         2/2     Running   0          2m
metrics-api-xxxxxxxxx-xxxxx     2/2     Running   0          2m
prometheus-xxxxxxxxx-xxxxx      2/2     Running   0          2m
tap-xxxxxxxxx-xxxxx             2/2     Running   0          2m
tap-injector-xxxxxxxxx-xxxxx    2/2     Running   0          2m
web-xxxxxxxxx-xxxxx             2/2     Running   0          2m
```

### 验证 Viz 安装

```bash
# 检查 Viz 扩展
linkerd viz check
```

### 访问 Dashboard

```bash
# 启动 Dashboard（会自动在浏览器中打开）
linkerd viz dashboard &
```

或者通过 port-forward 手动访问：

```bash
# 端口转发
kubectl -n linkerd-viz port-forward svc/web 8084:8084

# 然后在浏览器访问: http://localhost:8084
```

### 通过 Ingress 暴露 Dashboard（可选）

创建 Ingress 资源：

```yaml
# viz-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: linkerd-viz-ingress
  namespace: linkerd-viz
  annotations:
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
spec:
  ingressClassName: nginx
  rules:
    - host: linkerd.k8s.local  # 修改为你的域名
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8084
```

应用 Ingress：

```bash
kubectl apply -f viz-ingress.yaml
```

## 将应用加入 Service Mesh

### 方法 1: 自动注入（推荐）

为命名空间添加注解，该命名空间中的所有新 Pod 都会自动注入 Linkerd 代理：

```bash
# 为命名空间启用自动注入
kubectl annotate namespace <your-namespace> linkerd.io/inject=enabled

# 示例：为 default 命名空间启用
kubectl annotate namespace default linkerd.io/inject=enabled
```

然后重启该命名空间中的 Pod：

```bash
# 重启 Deployment
kubectl rollout restart deployment -n <your-namespace>
```

### 方法 2: 手动注入

对现有的 Deployment 进行注入：

```bash
# 获取 Deployment 清单，注入代理，然后重新应用
kubectl get deploy -n <namespace> <deployment-name> -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

### 方法 3: 在资源清单中添加注解

在 Pod 模板中添加注解：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        linkerd.io/inject: enabled  # 添加此注解
    spec:
      containers:
      - name: my-app
        image: my-app:latest
```

### 验证注入

检查 Pod 是否成功注入了 Linkerd 代理：

```bash
# 查看 Pod，应该有 2 个容器（应用容器 + linkerd-proxy）
kubectl get pods -n <namespace>

# 检查数据平面状态
linkerd -n <namespace> check --proxy
```

## 安装示例应用（Emojivoto）

Linkerd 提供了一个示例应用用于测试：

```bash
# 安装 Emojivoto 应用
curl -fsL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -

# 为 Emojivoto 注入 Linkerd 代理
kubectl get deploy -n emojivoto -o yaml \
  | linkerd inject - \
  | kubectl apply -f -

# 查看 Pod 状态
kubectl get pods -n emojivoto

# 访问应用（通过 port-forward）
kubectl -n emojivoto port-forward svc/web-svc 8080:80

# 在浏览器访问: http://localhost:8080
```

## 高可用（HA）模式安装

对于生产环境，建议使用高可用模式：

```bash
# 使用 --ha 标志安装
linkerd install --ha | kubectl apply -f -
```

或使用 Helm：

```bash
# 下载 Chart 获取 values-ha.yaml
helm fetch --untar linkerd/linkerd2

# 使用 HA 配置安装
helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$exp \
  -f linkerd2/values-ha.yaml \
  --namespace linkerd \
  --create-namespace \
  linkerd/linkerd2
```

HA 模式的特点：
- 控制平面组件有多个副本
- 配置了 Pod 反亲和性规则
- 设置了资源请求和限制
- 启用了 Pod 中断预算（PDB）

## 常见问题排查

### 1. 预检查失败

```bash
# 查看详细错误信息
linkerd check --pre -o json
```

### 2. Pod 无法启动

```bash
# 查看 Pod 日志
kubectl logs -n linkerd <pod-name> -c <container-name>

# 查看 Pod 事件
kubectl describe pod -n linkerd <pod-name>
```

### 3. 证书问题

```bash
# 检查证书有效期
linkerd check --proxy

# 查看证书详情
kubectl get secret -n linkerd linkerd-identity-issuer -o yaml
```

### 4. 代理注入失败

```bash
# 检查 webhook 配置
kubectl get mutatingwebhookconfiguration linkerd-proxy-injector

# 查看 proxy-injector 日志
kubectl logs -n linkerd deploy/linkerd-proxy-injector
```

## 卸载 Linkerd

如果需要卸载 Linkerd：

```bash
# 1. 移除应用中的代理注入
kubectl get deploy -n <namespace> -o yaml \
  | linkerd uninject - \
  | kubectl apply -f -

# 2. 卸载 Viz 扩展
linkerd viz uninstall | kubectl delete -f -

# 3. 卸载控制平面
linkerd uninstall | kubectl delete -f -

# 4. 清理命名空间（如果需要）
kubectl delete namespace linkerd linkerd-viz
```

## 参考资源

- [Linkerd 官方文档](https://linkerd.io/2.11/overview/)
- [Linkerd GitHub 仓库](https://github.com/linkerd/linkerd2)
- [Linkerd 2.11.1 Release Notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.11.1)
- [Linkerd Slack 社区](https://slack.linkerd.io/)

## 版本说明

本教程基于 **Linkerd stable-2.11.1** 版本编写。不同版本的安装步骤可能略有差异，请根据实际使用的版本参考相应的官方文档。

### 版本兼容性

| Linkerd 版本 | Kubernetes 版本 | 备注 |
|-------------|----------------|------|
| 2.11.x      | 1.21+          | 稳定版本 |
| 2.12.x      | 1.21+          | 新特性版本 |
| 2.13.x      | 1.22+          | 最新稳定版 |

---

**最后更新**: 2025-11-25
