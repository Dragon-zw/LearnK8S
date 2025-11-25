# Grafana PodSecurity 策略违规问题解决方案

## 问题描述

在 Kubernetes 1.31 环境中部署 Grafana 时遇到 PodSecurity 策略违规错误：

```
pods "grafana-xxx" is forbidden: violates PodSecurity "restricted:latest":
  - allowPrivilegeEscalation != false
  - unrestricted capabilities
  - restricted volume types (hostPath)
  - runAsNonRoot != true
  - runAsUser=0
  - seccompProfile
```

## 根本原因

Kubernetes 1.25+ 默认启用了 Pod Security Standards (PSS)，`linkerd-viz` 命名空间使用 `restricted` 级别的安全策略，要求：

1. **不允许权限提升** (`allowPrivilegeEscalation: false`)
2. **必须以非 root 用户运行** (`runAsNonRoot: true`)
3. **必须删除所有 capabilities** (`capabilities.drop: ["ALL"]`)
4. **不允许使用 hostPath 卷**
5. **必须设置 seccomp profile**

## 解决方案

### 修复内容

#### 1. Pod 级别安全上下文

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 472  # Grafana 默认用户 ID
    fsGroup: 472
    seccompProfile:
      type: RuntimeDefault
```

#### 2. Init 容器安全上下文

```yaml
initContainers:
  - name: download-dashboards
    image: "docker.io/busybox:1.36"
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 472
      capabilities:
        drop:
          - ALL
      seccompProfile:
        type: RuntimeDefault
```

#### 3. Grafana 容器安全上下文

```yaml
containers:
  - name: grafana
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 472
      capabilities:
        drop:
          - ALL
      seccompProfile:
        type: RuntimeDefault
```

#### 4. 存储卷类型

**错误配置**:
```yaml
volumes:
  - name: storage
    hostPath:  # ❌ 不允许
      path: /data/volumes/grafana
```

**正确配置**:
```yaml
volumes:
  - name: storage
    emptyDir: {}  # ✅ 允许
```

### 完整的修复示例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: linkerd-viz
spec:
  template:
    spec:
      # Pod 级别安全上下文
      securityContext:
        runAsNonRoot: true
        runAsUser: 472
        fsGroup: 472
        seccompProfile:
          type: RuntimeDefault
      
      # Init 容器
      initContainers:
        - name: download-dashboards
          image: "docker.io/busybox:1.36"
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 472
            capabilities:
              drop:
                - ALL
            seccompProfile:
              type: RuntimeDefault
          volumeMounts:
            - name: storage
              mountPath: "/var/lib/grafana"
      
      # 主容器
      containers:
        - name: grafana
          image: "docker.io/grafana/grafana:9.4.7"
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 472
            capabilities:
              drop:
                - ALL
            seccompProfile:
              type: RuntimeDefault
          volumeMounts:
            - name: storage
              mountPath: "/var/lib/grafana"
      
      # 卷配置
      volumes:
        - name: storage
          emptyDir: {}  # 使用 emptyDir 而不是 hostPath
```

## 验证修复

### 1. 检查 Pod 状态

```bash
kubectl get pods -n linkerd-viz -l app.kubernetes.io/name=grafana
```

**预期输出**:
```
NAME                       READY   STATUS    RESTARTS   AGE
grafana-xxx-yyy            2/2     Running   0          1m
```

### 2. 检查安全上下文

```bash
kubectl get pod -n linkerd-viz -l app.kubernetes.io/name=grafana -o yaml | grep -A 10 securityContext
```

### 3. 验证无警告信息

部署时不应该看到 PodSecurity 警告：

```bash
kubectl apply -f grafana.yaml -n linkerd-viz
```

**预期**: 无 `Warning: would violate PodSecurity` 信息

## 常见问题

### Q1: 为什么使用 UID 472？

**A**: 472 是 Grafana 官方镜像中预定义的用户 ID。可以通过以下命令验证：

```bash
docker run --rm grafana/grafana:9.4.7 id
# uid=472(grafana) gid=0(root) groups=0(root)
```

### Q2: emptyDir 会导致数据丢失吗？

**A**: 是的，emptyDir 在 Pod 重启后数据会丢失。如果需要持久化，应该使用 PersistentVolumeClaim (PVC)：

```yaml
volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: grafana-pvc
```

### Q3: 如何在保持安全的同时使用 hostPath？

**A**: 在 `restricted` 策略下不允许使用 hostPath。如果必须使用，需要：
1. 将命名空间的 Pod Security 级别降低到 `baseline` 或 `privileged`
2. 或者使用 PVC + StorageClass 替代 hostPath

### Q4: Init 容器权限问题怎么办？

**A**: 确保：
1. Init 容器使用支持非 root 用户的镜像（如 busybox）
2. 目录权限设置正确 (`chmod 777`)
3. 使用与主容器相同的 UID

## Pod Security Standards 级别

| 级别 | 说明 | 适用场景 |
|------|------|---------|
| **privileged** | 无限制 | 系统组件、特权应用 |
| **baseline** | 最小限制 | 传统应用迁移 |
| **restricted** | 严格限制 | 现代云原生应用（推荐） |

Linkerd Viz 使用 `restricted` 级别，这是最安全的配置。

## 参考资源

- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
- [Grafana 官方镜像](https://hub.docker.com/r/grafana/grafana)

---

**最后更新**: 2025-11-25
**适用版本**: Kubernetes 1.25+
