# Dapr 1.8.7 安装问题解决方案

## 问题描述

在使用 Helm 安装 Dapr 1.8.7 时,会遇到以下错误:

```
Error: INSTALLATION FAILED: 1 error occurred:
        * Configuration.dapr.io "daprsystem" is invalid: [spec.mtls.controlPlaneTrustDomain: Required value, spec.mtls.sentryAddress: Required value]
```

## 根本原因

Dapr 1.8.7 的 Helm Chart 存在一个 bug:
- Configuration CRD 要求 `spec.mtls.controlPlaneTrustDomain` 和 `spec.mtls.sentryAddress` 为必填字段
- 但 Helm Chart 生成的 Configuration 资源没有包含这两个字段
- 导致 Kubernetes API Server 拒绝创建该资源

## 解决方案

### 方案 1: 升级到更新版本(推荐)

使用 Dapr 1.9.0 或更高版本,该 bug 已被修复:

```bash
helm install dapr dapr/dapr \
  --namespace dapr-system \
  --create-namespace \
  --version 1.14.0
```

### 方案 2: 手动修复 1.8.7 版本

如果必须使用 1.8.7 版本,使用提供的脚本:

```bash
./install-dapr-1.8.7.sh
```

#### 脚本工作原理

1. **尝试安装** - 让 Helm 创建 namespace 和 CRD(会失败)
2. **清理失败的 release** - 删除失败的 Helm release
3. **手动创建 Configuration** - 创建包含必需字段的 Configuration 资源,并添加 Helm 管理标签
4. **重新安装** - 使用 `--skip-crds` 跳过 CRD 创建,复用手动创建的 Configuration

#### 关键配置

手动创建的 Configuration 包含:

```yaml
apiVersion: dapr.io/v1alpha1
kind: Configuration
metadata:
  name: daprsystem
  namespace: dapr-system
  labels:
    app.kubernetes.io/managed-by: Helm  # Helm 管理标识
  annotations:
    meta.helm.sh/release-name: dapr
    meta.helm.sh/release-namespace: dapr-system
spec:
  mtls:
    enabled: true
    workloadCertTTL: 24h
    allowedClockSkew: 15m
    controlPlaneTrustDomain: "cluster.local"  # 必需字段
    sentryAddress: "dapr-sentry.dapr-system.svc.cluster.local:80"  # 必需字段
```

## 验证安装

检查所有 Dapr 组件是否正常运行:

```bash
kubectl get pods -n dapr-system
```

预期输出(所有 Pod 应为 Running 状态):

```
NAME                                     READY   STATUS    RESTARTS   AGE
dapr-dashboard-6c849c7d6-ddsbk           1/1     Running   0          1m
dapr-operator-6d58485676-spc6j           1/1     Running   0          1m
dapr-placement-server-0                  1/1     Running   0          1m
dapr-sentry-7ffdb7658c-vd9lc             1/1     Running   0          1m
dapr-sidecar-injector-85896b944b-h9788   1/1     Running   0          1m
```

检查 Configuration 资源:

```bash
kubectl get configuration daprsystem -n dapr-system -o yaml
```

## 相关资源

- [Dapr 官方文档](https://docs.dapr.io/)
- [Dapr Helm Chart](https://github.com/dapr/dapr/tree/master/charts/dapr)
- [相关 GitHub Issue](https://github.com/dapr/dapr/issues)
