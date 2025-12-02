<font style="color:rgb(0, 0, 0);">Devtron(</font>[https://devtron.ai](https://devtron.ai)<font style="color:rgb(0, 0, 0);">) 是用 go 编写的用于 Kubernetes 交付工作流管理的开源软件。它被设计为一个自我服务平台，以开发者友好的方式在 Kubernetes 上运维和维护应用程序（AppOps）。</font>

![](https://cdn.nlark.com/yuque/0/2023/png/2555283/1701793542322-b3c6e81d-9f0f-445f-9165-4646fa85e77a.png)

## <font style="color:rgb(0, 0, 0);">🎉</font><font style="color:rgb(0, 0, 0);">1 Devtron 特性</font>
+ <font style="color:black;">零代码软件交付工作流</font>
    - <font style="color:rgb(1, 1, 1);">了解 kubernetes、测试、CD、SecOps 等领域的工作流，这样你就不必写脚本。</font>
    - <font style="color:rgb(1, 1, 1);">可重复使用和可组合的组件，使工作流易于构建使用。</font>
+ <font style="color:black;">多云部署</font>
    - <font style="color:rgb(1, 1, 1);">天然支持部署到多个 kubernetes 集群上</font>
+ <font style="color:black;">轻松实现开发-安全-运维一体化</font>
    - <font style="color:rgb(1, 1, 1);">全局、集群、环境和应用的多层次安全策略，实现高效的分层策略管理</font>
    - <font style="color:rgb(1, 1, 1);">行为驱动的安全策略</font>
    - <font style="color:rgb(1, 1, 1);">kubernetes 资源定义策略和异常情况</font>
    - <font style="color:rgb(1, 1, 1);">定义事件的策略，以便更快地解决问题</font>
+ <font style="color:black;">应用程序调试面板</font>
    - <font style="color:rgb(1, 1, 1);">所有历史的 kubernetes 事件都集中在一个地方</font>
    - <font style="color:rgb(1, 1, 1);">安全地访问所有清单，如 secret、configmap</font>
    - <font style="color:rgb(1, 1, 1);">cpu、ram、http 状态码和延迟等应用指标，并进行新旧对比</font>
    - <font style="color:rgb(1, 1, 1);">使用 grep 和 json 搜索日志</font>
    - <font style="color:rgb(1, 1, 1);">事件和日志之间的智能关联性</font>
+ <font style="color:black;">企业级的安全性和合规性</font>
    - <font style="color:rgb(1, 1, 1);">细粒度的访问控制；控制谁可以编辑配置，谁可以部署</font>
    - <font style="color:rgb(1, 1, 1);">审计日志，了解谁做了什么，什么时候做的</font>
    - <font style="color:rgb(1, 1, 1);">所有 CI 和 CD 事件的历史记录</font>
    - <font style="color:rgb(1, 1, 1);">影响应用程序的 Kubernetes 事件</font>
    - <font style="color:rgb(1, 1, 1);">相关的云事件及其对应用程序的影响</font>
    - <font style="color:rgb(1, 1, 1);">先进的工作流程策略，如分支环境，确保构建和部署管道的安全</font>
+ <font style="color:black;">了解 Gitops</font>
    - <font style="color:rgb(1, 1, 1);">通过 API 和 UI 暴露的 Gitops，使你不必与 Git 客户端交互</font>
    - <font style="color:rgb(1, 1, 1);">由 postgres 支持的 Gitops 更容易分析</font>
    - <font style="color:rgb(1, 1, 1);">实施比 git 更精细的访问控制</font>
+ <font style="color:black;">业务洞察</font>
    - <font style="color:rgb(1, 1, 1);">部署指标来衡量敏捷过程的成功，它可以捕捉到 mttr、变更失败率、部署频率、部署规模等。</font>
    - <font style="color:rgb(1, 1, 1);">审计日志以了解失败的原因</font>
    - <font style="color:rgb(1, 1, 1);">监测跨部署的变化，并轻松恢复</font>

![](https://cdn.nlark.com/yuque/0/2023/gif/2555283/1701793542257-f9053159-baba-477e-a260-698c9b59988b.gif)

## <font style="color:rgb(0, 0, 0);">🚀</font><font style="color:rgb(0, 0, 0);">2 安装 Devtron</font>
<font style="color:rgb(0, 0, 0);">默认的安装配置会使用 MinIO 来存储构建日志和缓存，可以直接使用下面的命令进行安装：</font>

```bash
helm repo add devtron https://helm.devtron.ai
helm install devtron devtron/devtron-operator --create-namespace --namespace devtroncd \
--set secrets.POSTGRESQL_PASSWORD=change-me
```

<font style="color:rgb(0, 0, 0);">但是官方的安装方式会从 GitHub 上面去下载很多脚本进行初始化，由于某些原因，可能我们没办法正常访问，这里我已经将所有的安装脚本和代码同步到了</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(30, 107, 184);">gitee</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(0, 0, 0);">上面，不用担心安装不上了。</font>

<font style="color:rgb(0, 0, 0);">首先 clone 安装脚本：</font>

```bash
git clone https://gitee.com/cnych/devtron-installation-script.git
cd devtron-installation-script
```

<font style="color:rgb(0, 0, 0);">这里我们使用 Helm3 来进行安装，我们只需要安装</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(30, 107, 184);">devtron-operator</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(0, 0, 0);">即可帮我们自动安装 devtron 了，命令如下所示：</font>

```bash
helm upgrade --install devtron ./charts/devtron --create-namespace --namespace devtroncd
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /Users/ych/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /Users/ych/.kube/config
W0624 11:00:57.798698 56125 warnings.go:67] apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
W0624 11:00:59.829583 56125 warnings.go:67] apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
NAME: devtron
LAST DEPLOYED: Thu Jun 24 11:01:00 2021
NAMESPACE: devtroncd
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:

1. Run the following command to get the default admin password. Default username is admin

   kubectl -n devtroncd get secret devtron-secret -o jsonpath='{.data.ACD_PASSWORD}' | base64 -d

2. You can watch the progress of Devtron microservices installation by the following command

   kubectl -n devtroncd get installers installer-devtron -o jsonpath='{.status.sync.status}'
```

<font style="color:rgb(0, 0, 0);">上面的命令会帮我们创建一个用于安装 devtron 的 Pod，该 Pod 会去读取我们的</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(30, 107, 184);">installaction-script</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(0, 0, 0);">脚本进行初始化安装，这个安装过程需要花一点时间，不过需要注意的是需要提供一个默认的 StorageClass，否则 MinIO 对应的 PVC 没办法绑定，也就安装不成功了，我这里是在代码仓库中明确指定的一个名为</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(30, 107, 184);">nfs-storage</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(0, 0, 0);">的 StorageClass，正常安装后会产生很多 Pod：</font>

![devtron pods](https://cdn.nlark.com/yuque/0/2023/png/2555283/1701793542321-0c7061f5-6e72-489c-abfd-6e1de92ab976.png)

<font style="color:rgb(0, 0, 0);">为了访问方便我这里还创建了一个 IngressRoute 对象用来绑定 Dashboard：</font>

```bash
# devtron-ingressroute.yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: devtron
  namespace: devtroncd
spec:
  entryPoints:
    - web
  routes:
    - kind: Rule
      match: Host(`devtron.k8s.local`)
      services:
        - name: devtron-service
          port: 80
```

<font style="color:rgb(0, 0, 0);">创建完成后我们就可以通过域名（提前做好解析）就可以访问 devtron 了。</font>

![login devtron](https://cdn.nlark.com/yuque/0/2023/png/2555283/1701793542347-758e46a3-e543-4311-af2c-72fb4705d19d.png)

<font style="color:rgb(0, 0, 0);">登录的时候使用的默认用户名为</font><font style="color:rgb(0, 0, 0);"> </font><font style="color:rgb(30, 107, 184);">admin</font><font style="color:rgb(0, 0, 0);">，密码则可以使用上面安装 Helm Charts 的时候的提示命令获取:</font>

```bash
kubectl -n devtroncd get secret devtron-secret -o jsonpath='{.data.ACD_PASSWORD}' | base64 -d
```

<font style="color:rgb(0, 0, 0);">登录后就可以进入到 Dashboard 的主页了：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/2555283/1701793542329-dde04355-449d-493c-b5e2-ea75c64513a3.png)

<font style="color:rgb(0, 0, 0);">进入 Dashboard 后我们还需要做一些配置才能使用，比如添加 Docker 镜像仓库、配置 gitops 等。具体使用方法可以参考官方文档说明 </font>[https://docs.devtron.ai](https://docs.devtron.ai)<font style="color:rgb(0, 0, 0);">，后续我们再提供一个详细的使用文档。</font>

> <font style="color:black;">仓库地址：</font>[https://github.com/devtron-labs/devtron](https://github.com/devtron-labs/devtron)
>

