# Linkerd 与 Kubernetes 1.31 兼容性问题解决方案

## 问题描述

在 Kubernetes 1.31.6 集群上安装 Linkerd 2.11.4 时遇到以下错误：

```
error: resource mapping not found for name: "linkerd-heartbeat" namespace: "linkerd" from "STDIN": 
no matches for kind "CronJob" in version "batch/v1beta1"
ensure CRDs are installed first
```

## 根本原因

### API 版本不兼容

| 组件 | 版本 | CronJob API 版本 |
|------|------|-----------------|
| Kubernetes 集群 | 1.31.6 | 仅支持 `batch/v1` |
| Linkerd | 2.11.4 | 使用 `batch/v1beta1` |

**时间线**:
- Kubernetes 1.21 (2021年4月): `batch/v1` CronJob API 稳定
- Kubernetes 1.25 (2022年8月): **移除** `batch/v1beta1` API
- Linkerd 2.11.x (2022年初): 仍使用 `batch/v1beta1`
- Linkerd 2.12+ (2022年末): 更新为 `batch/v1`

## 解决方案

### 方案 1: 升级到 Linkerd 2.14.x（强烈推荐）

Linkerd 2.14.x 是稳定版本，完全兼容 Kubernetes 1.31。

#### 步骤 1: 卸载当前的 Linkerd CLI

```bash
# 删除已安装的 CLI
sudo rm /usr/local/bin/linkerd

# 验证删除
which linkerd  # 应该没有输出
```

#### 步骤 2: 安装 Linkerd 2.14.10

```bash
# 下载 Linkerd 2.14.10
curl -sLO https://github.com/linkerd/linkerd2/releases/download/stable-2.14.10/linkerd2-cli-stable-2.14.10-linux-amd64

# 添加执行权限
chmod +x linkerd2-cli-stable-2.14.10-linux-amd64

# 移动到系统路径
sudo mv linkerd2-cli-stable-2.14.10-linux-amd64 /usr/local/bin/linkerd

# 验证安装
linkerd version --client
```

**预期输出**:
```
stable-2.14.10
```

#### 步骤 3: 运行预检查

```bash
linkerd check --pre
```

#### 步骤 4: 安装控制平面

```bash
# 安装 Linkerd 控制平面
linkerd install --crds | kubectl apply -f -

# 等待 CRD 就绪
sleep 5

# 安装控制平面组件
linkerd install | kubectl apply -f -
```

#### 步骤 5: 验证安装

```bash
# 等待 Pod 就绪
kubectl wait --for=condition=ready pod --all -n linkerd --timeout=300s

# 运行健康检查
linkerd check

# 查看版本
linkerd version
```

---

### 方案 2: 使用最新稳定版 Linkerd

如果不需要特定版本，建议使用最新稳定版。

```bash
# 删除旧版本 CLI
sudo rm /usr/local/bin/linkerd

# 安装最新稳定版
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

# 添加到 PATH
export PATH=$PATH:$HOME/.linkerd2/bin
echo 'export PATH=$PATH:$HOME/.linkerd2/bin' >> ~/.bashrc

# 安装控制平面
linkerd install --crds | kubectl apply -f -
sleep 5
linkerd install | kubectl apply -f -

# 验证
linkerd check
```

---

### 方案 3: 手动修复 CronJob API 版本（不推荐）

如果必须使用 Linkerd 2.11.x，可以手动修改生成的 YAML。

#### 步骤 1: 生成安装清单

```bash
linkerd install > linkerd-install.yaml
```

#### 步骤 2: 修改 CronJob API 版本

```bash
# 将 batch/v1beta1 替换为 batch/v1
sed -i 's/apiVersion: batch\/v1beta1/apiVersion: batch\/v1/g' linkerd-install.yaml
```

#### 步骤 3: 应用修改后的清单

```bash
kubectl apply -f linkerd-install.yaml
```

**注意**: 此方法可能导致其他兼容性问题，不建议用于生产环境。

---

## 版本兼容性矩阵

| Linkerd 版本 | Kubernetes 版本 | CronJob API | 推荐用于 K8s 1.31 |
|-------------|----------------|-------------|------------------|
| 2.11.x      | 1.21 - 1.24    | batch/v1beta1 | ❌ 不兼容 |
| 2.12.x      | 1.21 - 1.26    | batch/v1    | ⚠️ 可用但较旧 |
| 2.13.x      | 1.21 - 1.28    | batch/v1    | ⚠️ 可用但较旧 |
| 2.14.x      | 1.21 - 1.29    | batch/v1    | ✅ 推荐 |
| 2.15.x      | 1.21 - 1.30    | batch/v1    | ✅ 推荐 |
| edge        | 1.21+          | batch/v1    | ✅ 最新特性 |

## 清理已安装的资源

如果安装失败，需要清理资源：

```bash
# 删除命名空间（会删除大部分资源）
kubectl delete namespace linkerd

# 清理 CRD
kubectl delete crd \
  servers.policy.linkerd.io \
  serverauthorizations.policy.linkerd.io \
  serviceprofiles.linkerd.io \
  trafficsplits.split.smi-spec.io

# 清理 ClusterRole 和 ClusterRoleBinding
kubectl get clusterrole | grep linkerd | awk '{print $1}' | xargs kubectl delete clusterrole
kubectl get clusterrolebinding | grep linkerd | awk '{print $1}' | xargs kubectl delete clusterrolebinding

# 清理 Webhook 配置
kubectl delete mutatingwebhookconfiguration linkerd-proxy-injector-webhook-config
kubectl delete validatingwebhookconfiguration linkerd-sp-validator-webhook-config linkerd-policy-validator-webhook-config
```

## 推荐的安装流程（Kubernetes 1.31）

```bash
# 1. 清理环境
sudo rm -f /usr/local/bin/linkerd
kubectl delete namespace linkerd 2>/dev/null || true

# 2. 安装 Linkerd 2.14.10
curl -sLO https://github.com/linkerd/linkerd2/releases/download/stable-2.14.10/linkerd2-cli-stable-2.14.10-linux-amd64
chmod +x linkerd2-cli-stable-2.14.10-linux-amd64
sudo mv linkerd2-cli-stable-2.14.10-linux-amd64 /usr/local/bin/linkerd

# 3. 预检查
linkerd check --pre

# 4. 安装控制平面
linkerd install --crds | kubectl apply -f -
sleep 5
linkerd install | kubectl apply -f -

# 5. 等待就绪
kubectl wait --for=condition=ready pod --all -n linkerd --timeout=300s

# 6. 验证安装
linkerd check

# 7. 安装 Viz 扩展（可选）
linkerd viz install | kubectl apply -f -
kubectl wait --for=condition=ready pod --all -n linkerd-viz --timeout=300s
linkerd viz check

# 8. 查看版本
linkerd version
```

## 常见问题

### Q1: 为什么不能在 Kubernetes 1.31 上使用 Linkerd 2.11？

**A**: Kubernetes 1.25 开始移除了 `batch/v1beta1` API，而 Linkerd 2.11 仍在使用这个已废弃的 API 版本。这是硬性不兼容，无法绕过。

### Q2: Linkerd 2.14 和 2.11 有什么区别？

**A**: 主要区别：
- API 兼容性：2.14 使用 `batch/v1`，兼容新版 Kubernetes
- 功能增强：更好的策略支持、性能优化
- 安全性：更新的依赖和安全修复
- 稳定性：更多的 bug 修复

### Q3: 升级到 2.14 会影响现有应用吗？

**A**: 不会。Linkerd 的数据平面代理是向后兼容的，升级控制平面不会影响已注入代理的应用。

### Q4: 可以降级 Kubernetes 版本吗？

**A**: 不推荐。降级 Kubernetes 集群风险很高，建议升级 Linkerd 版本。

## 参考资源

- [Linkerd 2.14 Release Notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.14.10)
- [Kubernetes API 废弃指南](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [Linkerd 版本兼容性](https://linkerd.io/2/reference/k8s-versions/)
- [CronJob API 迁移指南](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#cronjob-v125)

## 总结

对于 Kubernetes 1.31.6 集群：
- ✅ **推荐**: 使用 Linkerd 2.14.10 或更新版本
- ⚠️ **不推荐**: 使用 Linkerd 2.11.x（API 不兼容）
- ❌ **不可行**: 降级 Kubernetes 版本

---

**最后更新**: 2025-11-25
