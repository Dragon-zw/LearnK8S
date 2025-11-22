# Tekton DinD 故障排查和解决方案

## 问题分析

根据日志输出,您的 Tekton Pipeline 失败的主要原因是:

```
failed to start containerd: timeout waiting for containerd to start
```

### 关键错误信息:
1. `cat: can't open '/proc/net/ip_tables_names': No such file or directory` - 缺少内核模块
2. `DeadlineExceeded: context deadline exceeded` - containerd 启动超时
3. `Cannot connect to the Docker daemon at tcp://localhost:2376` - Docker daemon 未能成功启动

## 解决方案

### 方案 1: 修复 DinD 配置 (已应用)

已经为您更新了 `task-docker-build.yaml`,添加了 `/var/lib/docker` 卷挂载:

```yaml
volumeMounts:
  - mountPath: /certs/client
    name: dind-certs
  - mountPath: /var/lib/docker
    name: dind-storage
```

**重新应用任务:**
```bash
kubectl apply -f /root/LearnK8S/11.DevOps\(GitOps\)/11.6.Tektion/Manifest/3.Tekton\ 流水线/DinD/task-docker-build.yaml
```

### 方案 2: 使用 Kaniko (推荐)

Kaniko 是 Google 开发的容器镜像构建工具,专为 Kubernetes 设计,**不需要特权容器**。

已创建 `task-kaniko-build.yaml` 文件。

**优势:**
- ✅ 不需要 privileged 权限
- ✅ 更安全
- ✅ 在 Kubernetes 中更稳定
- ✅ 支持缓存层

**使用步骤:**

1. **创建 Docker 凭证 Secret (如果还没有):**
```bash
kubectl create secret docker-registry docker-credentials \
  --docker-server=harbor.k8s.local \
  --docker-username=admin \
  --docker-password=YOUR_PASSWORD \
  -n default
```

2. **应用 Kaniko Task:**
```bash
kubectl apply -f /root/LearnK8S/11.DevOps\(GitOps\)/11.6.Tektion/Manifest/3.Tekton\ 流水线/DinD/task-kaniko-build.yaml
```

3. **更新 Pipeline 使用 Kaniko:**
修改 `test-pipeline-3.yaml` 中的 taskRef:
```yaml
- name: build-and-push
  taskRef:
    name: kaniko-build-push  # 改为使用 kaniko
```

### 方案 3: 检查节点内核模块

DinD 需要某些内核模块。在 Kubernetes 节点上检查:

```bash
# 在 Kubernetes 节点上执行
lsmod | grep ip_tables
lsmod | grep overlay
lsmod | grep br_netfilter

# 如果缺少,加载模块
modprobe ip_tables
modprobe overlay
modprobe br_netfilter
```

### 方案 4: 增加 DinD 启动等待时间

修改 readinessProbe,增加初始延迟:

```yaml
readinessProbe:
  initialDelaySeconds: 10  # 添加初始延迟
  periodSeconds: 2
  timeoutSeconds: 5
  exec:
    command: ['ls', '/certs/client/ca.pem']
```

### 方案 5: 使用不同的 DinD 镜像版本

尝试使用特定版本的 docker:dind:

```yaml
sidecars:
  - image: docker:20.10-dind  # 使用稳定版本
```

## 调试命令

### 查看 Pod 详细信息:
```bash
kubectl describe pod test-sidecar-pipelinerun-build-and-push-pod -n default
```

### 查看 sidecar 容器日志:
```bash
kubectl logs test-sidecar-pipelinerun-build-and-push-pod -n default -c sidecar-server
```

### 进入 Pod 调试:
```bash
kubectl exec -it test-sidecar-pipelinerun-build-and-push-pod -n default -c step-docker-build -- sh
# 在容器内测试 Docker 连接
docker version
docker info
```

### 检查证书生成:
```bash
kubectl exec -it test-sidecar-pipelinerun-build-and-push-pod -n default -c sidecar-server -- ls -la /certs/client/
```

## 推荐行动

**最佳实践:** 使用 **Kaniko** (方案 2),因为:
1. 在生产环境中更安全(不需要特权容器)
2. 专为 Kubernetes 设计
3. 避免 DinD 的复杂性和权限问题
4. 被广泛采用(Tekton、GitLab CI 等)

如果必须使用 DinD,建议:
1. 先应用方案 1 的修复
2. 检查节点内核模块(方案 3)
3. 尝试不同的镜像版本(方案 5)
