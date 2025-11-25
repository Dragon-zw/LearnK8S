# Linkerd iptables 初始化失败问题解决方案

## 问题描述

在 RHEL 8.10 + Kubernetes 1.31 + containerd 环境中安装 Linkerd 时，Pod 无法启动，报错：

```
time="2025-11-25T04:43:13Z" level=info msg="/sbin/iptables-save -t nat"
time="2025-11-25T04:43:13Z" level=info msg="modprobe: can't change directory to '/lib/modules': No such file or directory\niptables-save v1.8.9 (legacy): Cannot initialize: iptables who? (do you need to insmod?)\n"
time="2025-11-25T04:43:13Z" level=error msg="aborting firewall configuration"
Error: exit status 1
```

## 根本原因

### 问题分析

1. **Linkerd 默认使用 Init 容器配置 iptables**
   - `linkerd-init` 容器在 Pod 启动时配置 iptables 规则
   - 用于劫持进出 Pod 的流量到 Linkerd 代理

2. **RHEL/CentOS 环境的限制**
   - containerd 运行时的容器无法访问主机的 `/lib/modules`
   - 容器内无法加载内核模块（如 iptables 相关模块）
   - SELinux 或其他安全策略可能限制容器权限

3. **错误触发条件**
   - 容器尝试运行 `iptables-save` 命令
   - 需要加载内核模块但无权限
   - Init 容器失败，导致整个 Pod 无法启动

## 解决方案：使用 Linkerd CNI 插件

### 什么是 CNI 插件模式？

**CNI (Container Network Interface) 插件**是 Kubernetes 的网络插件机制：

- **传统模式**：使用 Init 容器 + iptables 配置流量劫持
- **CNI 模式**：使用 CNI 插件在 Pod 创建时自动配置网络规则

**优势**：
- ✅ 不需要特权容器
- ✅ 不需要 Init 容器
- ✅ 不需要 CAP_NET_ADMIN 权限
- ✅ 更安全，更符合最小权限原则
- ✅ 兼容性更好，适用于受限环境

### 安装步骤

#### 步骤 1: 清理现有安装（如果有）

```bash
# 卸载控制平面
linkerd uninstall | kubectl delete -f -

# 确认命名空间已删除
kubectl get ns linkerd
```

#### 步骤 2: 安装 Linkerd CNI 插件

```bash
# 安装 CNI 插件（必须先于控制平面安装）
linkerd install-cni | kubectl apply -f -

# 等待 CNI DaemonSet 就绪
kubectl wait --for=condition=ready pod -l k8s-app=linkerd-cni -n linkerd-cni --timeout=300s

# 验证 CNI 插件状态
kubectl get pods -n linkerd-cni
kubectl get daemonset -n linkerd-cni
```

**预期输出**：
```
NAME                 READY   STATUS    RESTARTS   AGE
linkerd-cni-xxxxx    1/1     Running   0          30s
linkerd-cni-xxxxx    1/1     Running   0          30s
linkerd-cni-xxxxx    1/1     Running   0          30s
linkerd-cni-xxxxx    1/1     Running   0          30s
```

> **注意**：CNI 插件会在每个节点上运行一个 Pod（DaemonSet）

#### 步骤 3: 安装 Linkerd CRD

```bash
# 安装 CRD
linkerd install --crds | kubectl apply -f -

# 等待 CRD 就绪
sleep 5
```

#### 步骤 4: 安装 Linkerd 控制平面（启用 CNI）

```bash
# 使用 --linkerd-cni-enabled 标志安装控制平面
linkerd install --linkerd-cni-enabled | kubectl apply -f -

# 等待控制平面 Pod 就绪
kubectl wait --for=condition=ready pod --all -n linkerd --timeout=300s
```

#### 步骤 5: 验证安装

```bash
# 运行健康检查
linkerd check

# 查看控制平面 Pod
kubectl get pods -n linkerd

# 查看版本
linkerd version
```

**预期输出**：
```
Client version: stable-2.14.10
Server version: stable-2.14.10
```

### 完整安装脚本

```bash
#!/bin/bash

echo "=== 清理现有 Linkerd 安装 ==="
linkerd uninstall | kubectl delete -f - 2>/dev/null || true
sleep 5

echo "=== 安装 Linkerd CNI 插件 ==="
linkerd install-cni | kubectl apply -f -

echo "=== 等待 CNI 插件就绪 ==="
kubectl wait --for=condition=ready pod -l k8s-app=linkerd-cni -n linkerd-cni --timeout=300s

echo "=== 验证 CNI 插件 ==="
kubectl get pods -n linkerd-cni

echo "=== 安装 Linkerd CRD ==="
linkerd install --crds | kubectl apply -f -
sleep 5

echo "=== 安装 Linkerd 控制平面（CNI 模式）==="
linkerd install --linkerd-cni-enabled | kubectl apply -f -

echo "=== 等待控制平面就绪 ==="
kubectl wait --for=condition=ready pod --all -n linkerd --timeout=300s

echo "=== 运行健康检查 ==="
linkerd check

echo "=== 查看版本 ==="
linkerd version

echo "=== 安装完成！==="
```

保存为 `install-linkerd-cni.sh`，然后执行：

```bash
chmod +x install-linkerd-cni.sh
./install-linkerd-cni.sh
```

## 验证 CNI 模式

### 检查 Pod 是否使用 CNI

查看注入了 Linkerd 代理的 Pod，应该**没有** `linkerd-init` 容器：

```bash
# 部署测试应用
kubectl create deployment nginx --image=nginx
kubectl annotate deployment nginx linkerd.io/inject=enabled
kubectl rollout restart deployment nginx

# 查看 Pod
kubectl get pod -l app=nginx -o jsonpath='{.items[0].spec.initContainers[*].name}'
```

**预期结果**：
- **传统模式**：会显示 `linkerd-init`
- **CNI 模式**：不显示任何 init 容器（或只显示应用自己的 init 容器）

### 检查 CNI 配置

```bash
# 查看 CNI 配置文件（在任意节点上）
kubectl exec -n linkerd-cni -it $(kubectl get pod -n linkerd-cni -o name | head -1) -- cat /host/etc/cni/net.d/10-linkerd.conflist
```

## 安装 Viz 扩展

```bash
# 安装 Viz 插件
linkerd viz install | kubectl apply -f -

# 等待 Viz 组件就绪
kubectl wait --for=condition=ready pod --all -n linkerd-viz --timeout=300s

# 验证 Viz
linkerd viz check

# 启动 Dashboard
linkerd viz dashboard &
```

## 故障排查

### 问题 1: CNI 插件 Pod 无法启动

**检查**：
```bash
kubectl describe pod -n linkerd-cni <pod-name>
kubectl logs -n linkerd-cni <pod-name>
```

**常见原因**：
- CNI 配置目录权限问题
- 与现有 CNI 插件冲突（如 Calico、Flannel）

**解决方案**：
```bash
# 检查节点上的 CNI 配置目录
ls -la /etc/cni/net.d/

# 确保 Linkerd CNI 配置优先级正确（文件名应该是 10-linkerd.conflist）
```

### 问题 2: 应用 Pod 仍然有 linkerd-init 容器

**原因**：控制平面安装时未启用 CNI 模式

**解决方案**：
```bash
# 重新安装控制平面，确保使用 --linkerd-cni-enabled 标志
linkerd install --linkerd-cni-enabled | kubectl apply -f -
```

### 问题 3: 网络连接问题

**检查**：
```bash
# 查看 iptables 规则（在应用 Pod 的网络命名空间中）
kubectl exec -it <pod-name> -c linkerd-proxy -- iptables -t nat -L -n -v
```

**注意**：在 CNI 模式下，iptables 规则由 CNI 插件配置，不在容器内部。

## 传统模式 vs CNI 模式对比

| 特性 | 传统模式（Init 容器） | CNI 模式 |
|------|---------------------|---------|
| 需要特权容器 | ✅ 是 | ❌ 否 |
| 需要 CAP_NET_ADMIN | ✅ 是 | ❌ 否 |
| Init 容器 | ✅ linkerd-init | ❌ 无 |
| 兼容受限环境 | ❌ 否 | ✅ 是 |
| 安装复杂度 | 低 | 中 |
| 安全性 | 中 | 高 |
| 性能 | 相同 | 相同 |
| 推荐用于生产 | ✅ 是 | ✅ 是 |

## 适用场景

### 推荐使用 CNI 模式的场景：

1. ✅ **RHEL/CentOS 环境**
2. ✅ **启用了 SELinux 的环境**
3. ✅ **受限的容器运行时环境**
4. ✅ **需要最小权限的安全环境**
5. ✅ **OpenShift 等企业 Kubernetes 平台**

### 可以使用传统模式的场景：

1. ✅ **标准 Kubernetes 环境**
2. ✅ **没有严格安全限制**
3. ✅ **快速测试和开发环境**

## 卸载

### 卸载 Linkerd（CNI 模式）

```bash
# 1. 卸载 Viz 扩展
linkerd viz uninstall | kubectl delete -f -

# 2. 卸载控制平面
linkerd uninstall | kubectl delete -f -

# 3. 卸载 CNI 插件
linkerd install-cni --uninstall | kubectl delete -f -

# 4. 清理命名空间
kubectl delete namespace linkerd linkerd-viz linkerd-cni
```

## 参考资源

- [Linkerd CNI 插件文档](https://linkerd.io/2.14/features/cni/)
- [Linkerd 安装选项](https://linkerd.io/2.14/reference/cli/install/)
- [Kubernetes CNI 规范](https://github.com/containernetworking/cni/blob/master/SPEC.md)

## 总结

对于 RHEL 8.10 + Kubernetes 1.31 + containerd 环境：

- ❌ **不推荐**：使用传统 Init 容器模式（会遇到 iptables 权限问题）
- ✅ **推荐**：使用 CNI 插件模式（完全兼容，更安全）

**关键安装命令**：
```bash
# 1. 安装 CNI 插件
linkerd install-cni | kubectl apply -f -

# 2. 安装 CRD
linkerd install --crds | kubectl apply -f -

# 3. 安装控制平面（启用 CNI）
linkerd install --linkerd-cni-enabled | kubectl apply -f -
```

---

**最后更新**: 2025-11-25
