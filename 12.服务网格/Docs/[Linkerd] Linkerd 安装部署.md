[<font style="color:rgb(28, 30, 33);">Linkerd</font>](https://linkerd.io/)<font style="color:rgb(28, 30, 33);"> 是 Kubernetes 的一个完全开源的服务网格实现。它通过为你提供运行时调试、可观测性、可靠性和安全性，使运行服务更轻松、更安全，所有这些都不需要对你的代码进行任何更改。</font>

`<font style="color:rgb(28, 30, 33);">Linkerd</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">通过在每个服务实例旁边安装一组超轻、透明的代理来工作。这些代理会自动处理进出服务的所有流量。由于它们是透明的，这些代理充当高度仪表化的进程外网络堆栈，向控制平面发送遥测数据并从控制平面接收控制信号。这种设计允许</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Linkerd</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">测量和操纵进出你的服务的流量，而不会引入过多的延迟。为了尽可能小、轻和安全，</font>`<font style="color:rgb(28, 30, 33);">Linkerd</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的代理采用 Rust 编写。</font>

## <font style="color:rgb(28, 30, 33);">功能概述</font>
+ `<font style="color:rgb(28, 30, 33);">自动 mTLS</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 自动为网格应用程序之间的所有通信启用相互传输层安全性 (TLS)。</font>
+ `<font style="color:rgb(28, 30, 33);">自动代理注入</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 会自动将数据平面代理注入到基于 annotations 的 pod 中。</font>
+ `<font style="color:rgb(28, 30, 33);">容器网络接口插件</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 能被配置去运行一个 CNI 插件，该插件自动重写每个 pod 的 iptables 规则。</font>
+ `<font style="color:rgb(28, 30, 33);">仪表板和 Grafana</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 提供了一个 Web 仪表板，以及预配置的 Grafana 仪表板。</font>
+ `<font style="color:rgb(28, 30, 33);">分布式追踪</font>`<font style="color:rgb(28, 30, 33);">：您可以在 Linkerd 中启用分布式跟踪支持。</font>
+ `<font style="color:rgb(28, 30, 33);">故障注入</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 提供了以编程方式将故障注入服务的机制。</font>
+ `<font style="color:rgb(28, 30, 33);">高可用性</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 控制平面可以在高可用性 (HA) 模式下运行。</font>
+ `<font style="color:rgb(28, 30, 33);">HTTP、HTTP/2 和 gRPC 代理</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 将自动为 HTTP、HTTP/2 和 gRPC 连接启用高级功能（包括指标、负载平衡、重试等）。</font>
+ `<font style="color:rgb(28, 30, 33);">Ingress</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 可以与您选择的 ingress controller 一起工作。</font>
+ `<font style="color:rgb(28, 30, 33);">负载均衡</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 会自动对 HTTP、HTTP/2 和 gRPC 连接上所有目标端点的请求进行负载平衡。</font>
+ `<font style="color:rgb(28, 30, 33);">多集群通信</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 可以透明且安全地连接运行在不同集群中的服务。</font>
+ `<font style="color:rgb(28, 30, 33);">重试和超时</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 可以执行特定于服务的重试和超时。</font>
+ `<font style="color:rgb(28, 30, 33);">服务配置文件</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 的服务配置文件支持每条路由指标以及重试和超时。</font>
+ `<font style="color:rgb(28, 30, 33);">TCP 代理和协议检测</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 能够代理所有 TCP 流量，包括 TLS 连接、WebSockets 和 HTTP 隧道。</font>
+ `<font style="color:rgb(28, 30, 33);">遥测和监控</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 会自动从所有通过它发送流量的服务收集指标。</font>
+ `<font style="color:rgb(28, 30, 33);">流量拆分(金丝雀、蓝/绿部署)</font>`<font style="color:rgb(28, 30, 33);">：Linkerd 可以动态地将一部分流量发送到不同的服务。</font>

## <font style="color:rgb(28, 30, 33);">架构</font>
<font style="color:rgb(28, 30, 33);">整体上来看</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Linkerd</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">由一个控制平面和一个数据平面组成。</font>

+ **<font style="color:rgb(28, 30, 33);">控制平面</font>**<font style="color:rgb(28, 30, 33);">是一组服务，提供对</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Linkerd</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">整体的控制。</font>
+ **<font style="color:rgb(28, 30, 33);">数据平面</font>**<font style="color:rgb(28, 30, 33);">由在每个服务实例</font>`<font style="color:rgb(28, 30, 33);">旁边</font>`<font style="color:rgb(28, 30, 33);">运行的透明微代理(micro-proxies)组成，作为 Pod 中的 Sidecar 容器运行，这些代理会自动处理进出服务的所有 TCP 流量，并与控制平面进行通信以进行配置。</font>

<font style="color:rgb(28, 30, 33);">此外 Linkerd 还提供了一个 CLI 工具，可用于控制平面和数据平面进行交互。</font>

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1735575510159-dbf9f54f-c40a-425e-8cce-cbbe84c9da34.jpeg)

**<font style="color:rgb(28, 30, 33);">控制平面(control plane)</font>**

<font style="color:rgb(28, 30, 33);">Linkerd 控制平面是一组在专用 Kubernetes 命名空间（默认为 linkerd）中运行的服务，控制平面有几个组件组成：</font>

+ `<font style="color:rgb(28, 30, 33);">目标服务(destination)</font>`<font style="color:rgb(28, 30, 33);">：数据平面代理使用 destination 服务来确定其行为的各个方面。它用于获取服务发现信息；获取有关允许哪些类型的请求的策略信息；获取用于通知每条路由指标、重试和超时的服务配置文件信息和其它有用信息。</font>
+ `<font style="color:rgb(28, 30, 33);">身份服务(identity)</font>`<font style="color:rgb(28, 30, 33);">：identity 服务充当 TLS 证书颁发机构，接受来自代理的 CSR 并返回签名证书。这些证书在代理初始化时颁发，用于代理到代理连接以实现 mTLS。</font>
+ `<font style="color:rgb(28, 30, 33);">代理注入器(proxy injector)</font>`<font style="color:rgb(28, 30, 33);">：proxy injector 是一个 Kubernetes admission controller，它在每次创建 pod 时接收一个 webhook 请求。 此 injector 检查特定于 Linkerd 的 annotation（linkerd.io/inject: enabled）的资源。 当该 annotation 存在时，injector 会改变 pod 的规范， 并将 proxy-init 和 linkerd-proxy 容器以及相关的启动时间配置添加到 pod 中。</font>

**<font style="color:rgb(28, 30, 33);">数据平面(data plane)</font>**

<font style="color:rgb(28, 30, 33);">Linkerd 数据平面包含超轻型微代理，这些微代理部署为应用程序 Pod 内的 sidecar 容器。 由于由</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd-init</font>`<font style="color:rgb(28, 30, 33);">（或者，由 Linkerd 的 CNI 插件）制定的 iptables 规则， 这些代理透明地拦截进出每个 pod 的 TCP 连接。</font>

+ <font style="color:rgb(28, 30, 33);">代理(Linkerd2-proxy)：</font>`<font style="color:rgb(28, 30, 33);">Linkerd2-proxy</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">是一个用 Rust 编写的超轻、透明的微代理。</font>`<font style="color:rgb(28, 30, 33);">Linkerd2-proxy</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">专为 service mesh 用例而设计，并非设计为通用代理。代理的功能包括：</font>
    - <font style="color:rgb(28, 30, 33);">HTTP、HTTP/2 和任意 TCP 协议的透明、零配置代理。</font>
    - <font style="color:rgb(28, 30, 33);">HTTP 和 TCP 流量的自动 Prometheus 指标导出。</font>
    - <font style="color:rgb(28, 30, 33);">透明、零配置的 WebSocket 代理。</font>
    - <font style="color:rgb(28, 30, 33);">自动、延迟感知、第 7 层负载平衡。</font>
    - <font style="color:rgb(28, 30, 33);">非 HTTP 流量的自动第 4 层负载平衡。</font>
    - <font style="color:rgb(28, 30, 33);">自动 TLS。</font>
    - <font style="color:rgb(28, 30, 33);">按需诊断 Tap API。</font>
    - <font style="color:rgb(28, 30, 33);">代理支持通过 DNS 和目标 gRPC API 进行服务发现。</font>
+ <font style="color:rgb(28, 30, 33);">Linkerd init 容器：</font>`<font style="color:rgb(28, 30, 33);">linkerd-init</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">容器作为 Kubernetes 初始化容器添加到每个网格 Pod 中，该容器在任何其他容器启动之前运行。它使用 iptables 通过代理将所有 TCP 流量，路由到 Pod 和从 Pod 发出。</font>

## <font style="color:rgb(28, 30, 33);">安装</font>
<font style="color:rgb(28, 30, 33);">我们可以通过在本地安装一个 Linkerd 的 CLI 命令行工具，通过该 CLI 可以将 Linkerd 的控制平面安装到 Kubernetes 集群上。</font>

<font style="color:rgb(28, 30, 33);">所以首先需要在本地运行 kubectl 命令，确保可以访问一个可用的 Kubernetes 集群，如果没有集群，可以使用 KinD 在本地快速创建一个。</font>

```shell
$ kubectl version --short
Client Version: v1.23.5
Server Version: v1.22.8
```

<font style="color:rgb(28, 30, 33);">可以使用下面的命令在本地安装 Linkerd 的 CLI 工具：</font>

```shell
$ curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

<font style="color:rgb(28, 30, 33);">如果是 Mac 系统，同样还可以使用 Homebrew 工具一键安装：</font>

```shell
$ brew install linkerd
```

<font style="color:rgb(28, 30, 33);">同样直接前往 Linkerd Release 页面</font><font style="color:rgb(28, 30, 33);"> </font>[<font style="color:rgb(28, 30, 33);">https://github.com/linkerd/linkerd2/releases/</font>](https://github.com/linkerd/linkerd2/releases/)<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">下载安装即可。</font>

<font style="color:rgb(28, 30, 33);">安装后使用下面的命令可以验证 CLI 工具是否安装成功：</font>

```shell
$ linkerd  version
Client version: stable-2.11.1
Server version: unavailable
```

<font style="color:rgb(28, 30, 33);">正常我们可以看到 CLI 的版本信息，但是会出现</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Server version: unavailable</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">信息，这是因为我们还没有在 Kubernetes 集群上安装控制平面造成的，所以接下来我们就来安装 Server 端。</font>

<font style="color:rgb(28, 30, 33);">Kubernetes 集群可以通过多种不同的方式进行配置，在安装 Linkerd 控制平面之前，我们需要检查并验证所有配置是否正确，要检查集群是否已准备好安装 Linkerd，可以执行下面的命令：</font>

```shell
$ linkerd check --pre
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

linkerd-version
---------------
√ can determine the latest version
‼ cli is up-to-date
    is running version 2.11.1 but the latest stable version is 2.11.4
    see https://linkerd.io/2.11/checks/#l5d-version-cli for hints

Status check results are √
```

<font style="color:rgb(28, 30, 33);">如果一切检查都 OK 则可以开始安装 Linkerd 的控制平面了，直接执行下面的命令即可一键安装：</font>

```shell
$ linkerd install | kubectl apply -f -
```

<font style="color:rgb(28, 30, 33);">在此命令中，</font>`<font style="color:rgb(28, 30, 33);">linkerd install</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">会生成一个 Kubernetes 资源清单文件，其中包含所有必要的控制平面资源，然后使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">kubectl apply</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令即可将其安装到 Kubernetes 集群中。</font>

<font style="color:rgb(28, 30, 33);">可以看到会将 Linkerd 控制面安装到一个名为</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的命名空间之下，安装完成后会有如下几个 Pod 运行：</font>

```shell
$ kubectl get pods -n linkerd
NAME                                      READY   STATUS    RESTARTS       AGE
linkerd-destination-79d6fc496f-dcgfx      4/4     Running   0              166m
linkerd-identity-6b78ff444f-jwp47         2/2     Running   0              166m
linkerd-proxy-injector-86f7f649dc-v576m   2/2     Running   0              166m
```

<font style="color:rgb(28, 30, 33);">安装完成后通过运行以下命令等待控制平面准备就绪，并可以验证安装结果是否正常：</font>

```shell
$ linkerd check

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

linkerd-webhooks-and-apisvc-tls
-------------------------------
√ proxy-injector webhook has valid cert
√ proxy-injector cert is valid for at least 60 days
√ sp-validator webhook has valid cert
√ sp-validator cert is valid for at least 60 days
√ policy-validator webhook has valid cert
√ policy-validator cert is valid for at least 60 days

linkerd-version
---------------
√ can determine the latest version
‼ cli is up-to-date
    is running version 2.11.1 but the latest stable version is 2.11.4
    see https://linkerd.io/2.11/checks/#l5d-version-cli for hints

control-plane-version
---------------------
√ can retrieve the control plane version
‼ control plane is up-to-date
    is running version 2.11.1 but the latest stable version is 2.11.4
    see https://linkerd.io/2.11/checks/#l5d-version-control for hints
√ control plane and cli versions match

linkerd-control-plane-proxy
---------------------------
√ control plane proxies are healthy
‼ control plane proxies are up-to-date
    some proxies are not running the current version:
        * linkerd-destination-79d6fc496f-dcgfx (stable-2.11.1)
        * linkerd-identity-6b78ff444f-jwp47 (stable-2.11.1)
        * linkerd-proxy-injector-86f7f649dc-v576m (stable-2.11.1)
    see https://linkerd.io/2.11/checks/#l5d-cp-proxy-version for hints
√ control plane proxies and cli versions match

Status check results are √
```

<font style="color:rgb(28, 30, 33);">当出现上面的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Status check results are √</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">信息后表示 Linkerd 的控制平面安装成功了。除了使用 CLI 工具的方式安装控制平面之外，我们也可以通过 Helm Chart 的方式来安装，如下所示：</font>

```shell
$ helm repo add linkerd https://helm.linkerd.io/stable
# set expiry date one year from now, in Mac:
$ exp=$(date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")
# in Linux:
$exp=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ")

$ helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$exp \
  linkerd/linkerd2
```

<font style="color:rgb(28, 30, 33);">此外该 chart 包含一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">values-ha.yaml</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">文件， 它覆盖了一些默认值，以便在高可用性场景下进行设置， 类似于</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd install</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">中的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">--ha</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">选项。我们可以通过获取 chart 文件来获得</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">values-ha.yaml</font>`<font style="color:rgb(28, 30, 33);">：</font>

```shell
$ helm fetch --untar linkerd/linkerd2
```

<font style="color:rgb(28, 30, 33);">然后使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">-f flag</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">提供覆盖文件，例如：</font>

```shell
## see above on how to set $exp
helm install linkerd2 \
  --set-file identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$exp \
  -f linkerd2/values-ha.yaml \
  linkerd/linkerd2
```

<font style="color:rgb(28, 30, 33);">采用哪种方式进行安装均可，到这里我们现在就完成了 Linkerd 的安装，重新执行</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd version</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令就可以看到 Server 端版本信息了：</font>

```shell
$ linkerd version
Client version: stable-2.11.1
Server version: stable-2.11.1
```

## <font style="color:rgb(28, 30, 33);">示例</font>
<font style="color:rgb(28, 30, 33);">接下来我们安装一个简单的示例应用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);">，该应用是一个简单的独立 Kubernetes 应用程序，它混合使用 gRPC 和 HTTP 调用，允许用户对他们最喜欢的表情符号进行投票。</font>

<font style="color:rgb(28, 30, 33);">通过运行以下命令可以将</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">安装到</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间中：</font>

```shell
$ curl -fsL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
namespace/emojivoto created
serviceaccount/emoji created
serviceaccount/voting created
serviceaccount/web created
service/emoji-svc created
service/voting-svc created
service/web-svc created
deployment.apps/emoji created
deployment.apps/vote-bot created
deployment.apps/voting created
deployment.apps/web created
```

<font style="color:rgb(28, 30, 33);">该应用下可以看到一共包含 4 个 Pod 服务。</font>

```shell
$ kubectl get pods -n emojivoto
NAME                        READY   STATUS    RESTARTS   AGE
emoji-66ccdb4d86-6vqvt      1/1     Running   0          91s
vote-bot-69754c864f-k26fb   1/1     Running   0          91s
voting-f999bd4d7-k44nb      1/1     Running   0          91s
web-79469b946f-bz295        1/1     Running   0          91s
$ kubectl get svc -n emojivoto
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
emoji-svc    ClusterIP   10.111.7.125     <none>        8080/TCP,8801/TCP   2m49s
voting-svc   ClusterIP   10.105.192.118   <none>        8080/TCP,8801/TCP   2m48s
web-svc      ClusterIP   10.111.236.171   <none>        80/TCP              2m48s
```

<font style="color:rgb(28, 30, 33);">我们可以通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">port-forward</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">来暴露</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">web-svc</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务，然后便可在浏览器中访问该应用。</font>

```shell
$ kubectl -n emojivoto port-forward svc/web-svc 8080:80
```

<font style="color:rgb(28, 30, 33);">现在我们可以在浏览器通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">http://localhost:8080</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">访问</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用了。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575511311-3513d859-c40c-4213-99e7-da7948a7c329.png)

<font style="color:rgb(28, 30, 33);">我们可以选择页面中喜欢的表情进行投票，但是选择某些表情后会出现一些错误，比如当我们点击甜甜圈表情符号的时候会得到一个 404 页面。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575511122-5c9b1907-8f65-4687-8274-3cbb5f12d6f5.png)

<font style="color:rgb(28, 30, 33);">不过不用担心，这是应用中故意留下的错误，为的是后面使用 Linkerd 来识别该问题。</font>

<font style="color:rgb(28, 30, 33);">接下来我们可以将上面的示例应用加入到 Service Mesh 中来，向其添加 Linkerd 的数据平面代理，直接运行下面的命令即可将</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用网格化：</font>

```shell
$ kubectl get -n emojivoto deploy -o yaml \
 | linkerd inject - \
 | kubectl apply -f -

deployment "emoji" injected
deployment "vote-bot" injected
deployment "voting" injected
deployment "web" injected

deployment.apps/emoji configured
deployment.apps/vote-bot configured
deployment.apps/voting configured
deployment.apps/web configured
```

<font style="color:rgb(28, 30, 33);">上面的命令首先获取在</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间中运行的所有 Deployments，然后通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd inject</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">运行它们的清单，然后将其重新应用到集群。</font>

<font style="color:rgb(28, 30, 33);">注意</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd inject</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令只是在 Pod 规范中添加一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd.io/inject: enabled</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的注解，并不会直接注入一个 Sidecar 容器，该注解即可指示 Linkerd 在创建 Pod 时将代理注入到其中，所以执行上面的命令后应用 Pod 中会新增一个 sidecar 的代理容器。</font>

```shell
$ kubectl get pods -n emojivoto
NAME                        READY   STATUS    RESTARTS   AGE
emoji-696d9d8f95-8wrmg      2/2     Running   0          34m
vote-bot-6d7677bb68-c98kb   2/2     Running   0          34m
voting-ff4c54b8d-rdtmk      2/2     Running   0          34m
web-5f86686c4d-qh5bz        2/2     Running   0          34m
```

<font style="color:rgb(28, 30, 33);">可以看到每个 Pod 现在都有 2 个容器，相较于之前多了一个 Linkerd 的 sidecar 代理容器。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575509509-8faa8a14-d55c-4888-b4f1-4b55b0f631c6.png)

<font style="color:rgb(28, 30, 33);">当应用更新完成后，我们就成功将应用引入到 Linkerd 的网格服务中来了，新增的代理容器组成了数据平面，我们也可以通过下面的命令检查数据平面状态：</font>

```shell
$ linkerd -n emojivoto check --proxy
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

linkerd-webhooks-and-apisvc-tls
-------------------------------
√ proxy-injector webhook has valid cert
√ proxy-injector cert is valid for at least 60 days
√ sp-validator webhook has valid cert
√ sp-validator cert is valid for at least 60 days
√ policy-validator webhook has valid cert
√ policy-validator cert is valid for at least 60 days

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA

linkerd-version
---------------
√ can determine the latest version
‼ cli is up-to-date
    is running version 2.11.1 but the latest stable version is 2.11.4
    see https://linkerd.io/2.11/checks/#l5d-version-cli for hints

linkerd-control-plane-proxy
---------------------------
√ control plane proxies are healthy
‼ control plane proxies are up-to-date
    some proxies are not running the current version:
        * linkerd-destination-79d6fc496f-dcgfx (stable-2.11.1)
        * linkerd-identity-6b78ff444f-jwp47 (stable-2.11.1)
        * linkerd-proxy-injector-86f7f649dc-v576m (stable-2.11.1)
    see https://linkerd.io/2.11/checks/#l5d-cp-proxy-version for hints
√ control plane proxies and cli versions match

linkerd-data-plane
------------------
√ data plane namespace exists
√ data plane proxies are ready
‼ data plane is up-to-date
    some proxies are not running the current version:
        * emoji-696d9d8f95-8wrmg (stable-2.11.1)
        * vote-bot-6d7677bb68-c98kb (stable-2.11.1)
        * voting-ff4c54b8d-rdtmk (stable-2.11.1)
        * web-5f86686c4d-qh5bz (stable-2.11.1)
    see https://linkerd.io/2.11/checks/#l5d-data-plane-version for hints
√ data plane and cli versions match
√ data plane pod labels are configured correctly
√ data plane service labels are configured correctly
√ data plane service annotations are configured correctly
√ opaque ports are properly annotated

Status check results are √
```

<font style="color:rgb(28, 30, 33);">当然，我们还是可以通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">http://localhost:8080</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">访问应用，当然在使用上和之前没什么区别，我们可以通过 Linkerd 去查看应用实际上做了哪些事情，但是我们需要去单独安装一个插件，由于 Linkerd 的核心控制平面非常轻量级， 所以 Linkerd 附带了一些插件，这些插件为 Linkerd 添加了一些非关键但通常有用的功能，包括各种仪表板，比如我们可以安装一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">viz</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">插件，</font>`<font style="color:rgb(28, 30, 33);">Linkerd-Viz</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">插件包含 Linkerd 的可观察性和可视化组件。安装命令如下所示：</font>

```shell
$ linkerd viz install | kubectl apply -f -
```

<font style="color:rgb(28, 30, 33);">上面的命令会创建一个名为</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd-viz</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的命名空间，会在该命名空间中安装监控相关的应用，比如 Prometheus、Grafana 等。</font>

```shell
$ kubectl get pods -n linkerd-viz
NAME                            READY   STATUS    RESTARTS   AGE
grafana-8d54d5f6d-wwtdz         2/2     Running   0          3h1m
metrics-api-6c59967bf4-pjwdq    2/2     Running   0          4h22m
prometheus-7bbc4d8c5b-5rc8r     2/2     Running   0          4h22m
tap-599c774dfb-m2kqz            2/2     Running   0          4h22m
tap-injector-748d54b7bc-jvshs   2/2     Running   0          4h22m
web-db97ff489-5599v             2/2     Running   0          4h22m
```

<font style="color:rgb(28, 30, 33);">安装完成后，我们可以使用下面的命令打开一个 dashboard 页面：</font>

```shell
$ linkerd viz dashboard &
```

<font style="color:rgb(28, 30, 33);">当</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">viz</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">插件部署完成后，执行上面的命令后会自动在浏览器中打开一个 Linkerd 的可观察性的 Dashboard。</font>

<font style="color:rgb(28, 30, 33);">此外我们也可以通过 Ingress 来暴露 viz 服务，创建如下所示的资源对象：</font>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
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
    - host: linkerd.k8s.local
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

<font style="color:rgb(28, 30, 33);">应用后就可以通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd.k8s.local</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">访问 viz 了。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575509503-10686296-d46a-44fc-9242-2bb9fac24904.png)

<font style="color:rgb(28, 30, 33);">还可以显示自动生成的拓扑图。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575510032-f40c6912-bd17-43ac-95bf-fe45db4eac61.png)

<font style="color:rgb(28, 30, 33);">在页面上我们可以找到每个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">组件的实时指标，就可以确定哪个组件出现了部分故障了，这样就可以有针对性的去解决问题了。</font>

<font style="color:rgb(28, 30, 33);">在对应的资源后面包含一个 Grafana 的图标，点击可以自动跳转到 Grafana 的监控页面。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575510095-6dc7aebb-1fce-490c-aca4-bbae8a155db6.png)

