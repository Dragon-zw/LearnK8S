Zadig 是 [KodeRover 公司](https://koderover.com/)基于 Kubernetes 自主设计、研发的开源分布式持续交付产品，具备灵活易用的高并发工作流、面向开发者的云原生环境、高效协同的测试管理、强大免运维的模板库、客观精确的效能洞察以及云原生 IDE 插件等重要特性，为工程师提供统一的协作平面。Zadig 内置了 K8s YAML、Helm Chart、主机等复杂场景最佳实践，适用大规模微服务、高频高质量交付等场景。

## 1 核心概念
在使用 Zadig 之前我们这里先来了解下 Zadig 中的几个核心概念。

+ **项目**：Zadig 中的项目包括工作流、环境、服务、构建、测试、版本等资源，用户在项目中可以进行服务开发、服务部署、集成测试、版本发布等操作。
+ **工作流**：典型的软件开发过程一般包括 `<font style="color:#DF2A3F;">编写代码 -> 构建 -> 部署 -> 测试 -> 发布</font>` 这几个步骤，工作流就是 Zadig 平台对这样一个开发流程的实现，通过工作流来更新环境中的服务或者配置。
+ **工作流组成**：Zadig 工作流简化示意图如下所示：

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347096693-5e9d702d-5ba4-4ea2-9ae1-0b1b10dbf3be.jpeg)

目前工作流基本组成部分有：

    - 构建：拉取代码，执行构建
    - 部署：将构建产物部署到测试环境中
    - 测试：执行自动化测试，对部署结果进行验证
    - 分发：完成测试验证后，将构建产物分发到待发布的仓库
+ **环境**：Zadig 环境是一组服务集合及其配置、运行环境的总称，与 Kubernetes 的 NameSpace 是一对一的对应关系，使用一套服务模板可以创建多套环境。
+ **服务**：Zadig 中的服务可以理解为一组 Kubernetes 资源，包括 Ingress、Service、Deployment/Statefulset、ConfigMap 等，也可以是一个完整的 Helm Chart 或者云主机/物理机服务，成功部署后可对外提供服务能力。
+ **服务组件**：服务组件是 Zadig 中可被更新的最小单元，是使用 Kubernetes 作为基础设施的项目中的概念。一个服务中可包括多个服务组件。不同项目中的服务组件信息如下表： ![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347103917-91a3e985-98c7-49ce-9064-b6cca72e3f88.png) 服务组件是服务构建配置中的一部分，为服务组件配置构建后，运行工作流时可选择对应的服务组件对其进行更新。
+ **构建**：Zadig 构建属于服务配置的一部分，同时在工作流运行阶段会被调用，与服务是一对多的对应关系，即一套构建可以支持多个服务共享。
+ **测试**：Zadig 测试属于项目的资源，同时也可以作为一个非必要阶段在工作流中调用，支持跨项目。
+ **版本管理**：Zadig 版本是一个完整的可靠交付物，比如 Helm Chart，或 K8s YAML 完整配置文件。

## 2 安装
Zadig 官网提供了几种部署方式，这里我们选择使用 Helm Chart 的方式部署到 K8s 集群中。

**部署**

首先添加 Zadig 的 Chart 仓库。

```shell
$ helm repo add koderover-chart https://koderover.tencentcloudcr.com/chartrepo/chart
$ helm repo update
```

获取 chart 包：

```shell
$ helm pull koderover-chart/zadig --untar
```

创建如下所示的 values 文件：

```yaml
# ci/local-values.yaml
tags:
  mongodb: true
  minio: true
  ingressController: false
  mysql: true

endpoint:
  type: FQDN
  FQDN: zadig.k8s.local

dex:
  config:
    staticClients:
      - id: zadig
        redirectURIs:
          - 'http://zadig.k8s.local/api/v1/callback'
        name: 'zadig'
        secret: ZXhhbXBsZS1hcHAtc2VjcmV0
```

Zadig 需要依赖 mongodb、minio 以及 mysql 服务，如果你没有外部的服务可用，则可以使用内置的服务，通过 `tags` 下面的属性来配置是否开启即可，`endpoint.FQDN` 用来配置 zadig 服务的地址。然后我们就可以使用该 values 文件来部署 zadig 了：

```shell
$ kubectl create ns zadig
$ helm upgrade --install zadig . -f ci/local-values.yaml --namespace zadig
NAME: zadig
LAST DEPLOYED: Mon Jul 11 14:21:16 2022
NAMESPACE: zadig
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Zadig has been installed successfully.

An initial account has been generated for your first login:
- Login:  zadig.k8s.local
- User: admin
- Password: zadig

Add wechat ID "guotimeme": get FREE Zadig Tech Support, and Join our online community.
```

部署完成后查看 zadig 相关服务状态：

```shell
$ kubectl get pods -n zadig
NAME                              READY   STATUS      RESTARTS       AGE
aslan-69d6759654-rtsrn            2/2     Running     0              155m
config-547fb89564-vkj84           1/1     Running     1 (153m ago)   155m
cron-f8544788c-5b8fl              2/2     Running     1 (143m ago)   155m
dind-0                            1/1     Running     0              155m
discovery-74945fc6d4-sn8ws        1/1     Running     0              155m
gateway-6bdf56976-gg4nx           1/1     Running     3 (154m ago)   155m
gateway-proxy-f7d46ccb9-bln5j     1/1     Running     0              155m
gloo-66d69d848f-khvfk             1/1     Running     0              155m
hub-server-7fb68b65cb-4c7lp       1/1     Running     0              155m
nsqlookup-0                       1/1     Running     0              155m
opa-b5df66445-stjjp               1/1     Running     0              155m
picket-84d4758c5f-kp88l           1/1     Running     0              155m
podexec-57db555984-tgrk8          1/1     Running     0              155m
policy-67f7d4f744-n9g5l           1/1     Running     0              155m
resource-server-bcd7cd7f8-krpg6   1/1     Running     0              155m
user-5c95bb8fb7-z8wg5             1/1     Running     1 (153m ago)   155m
warpdrive-7ffff47d47-n2vwb        2/2     Running     0              155m
warpdrive-7ffff47d47-rwpq4        2/2     Running     0              155m
zadig-dex-c575978d9-n68q9         1/1     Running     1 (150m ago)   155m
zadig-init--1-f98xb               0/1     Completed   0              155m
zadig-minio-fb7fdd6b6-cfjss       1/1     Running     0              155m
zadig-mongodb-5c59975745-4s24h    1/1     Running     0              155m
zadig-mysql-0                     1/1     Running     0              155m
zadig-portal-5cdd6d9fdd-6g8ds     1/1     Running     0              155m
```

可以看到 zadig 的依赖服务还是比较多的，默认情况下 zadig 会使用 `<font style="color:#DF2A3F;">gloo</font>` 这种 ingress 控制器来暴露服务，会创建一个名为 `<font style="color:#DF2A3F;">zadig</font>` 的 `<font style="color:#DF2A3F;">virtualservices</font>` 对象，该对象相当于 Ingress 的一个高级版本。

```shell
$ kubectl get virtualservices zadig -n zadig
NAME    AGE
zadig   171m
$ kubectl get svc -n zadig
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                               AGE
aslan                  ClusterIP      10.97.27.165     <none>          25000/TCP                             172m
config                 ClusterIP      10.107.241.188   <none>          80/TCP                                172m
dind                   ClusterIP      None             <none>          2375/TCP                              172m
gateway                ClusterIP      10.99.26.142     <none>          443/TCP                               172m
gateway-proxy          LoadBalancer   10.111.109.206   192.168.0.102   80:31600/TCP,443:31572/TCP            172m
gloo                   ClusterIP      10.103.178.8     <none>          9977/TCP,9976/TCP,9988/TCP,9979/TCP   172m
hub-server             ClusterIP      10.109.70.132    <none>          26000/TCP                             172m
nsqlookupd             ClusterIP      None             <none>          4160/TCP,4161/TCP                     172m
opa                    ClusterIP      10.111.93.64     <none>          9191/TCP,8181/TCP                     172m
picket                 ClusterIP      10.97.6.111      <none>          80/TCP                                172m
podexec                ClusterIP      10.100.251.156   <none>          27000/TCP                             172m
policy                 ClusterIP      10.105.50.162    <none>          80/TCP                                172m
resource-server        ClusterIP      10.111.41.231    <none>          80/TCP                                172m
user                   ClusterIP      10.106.85.172    <none>          80/TCP                                172m
warpdrive              ClusterIP      10.107.219.101   <none>          25001/TCP                             172m
zadig-dex              ClusterIP      10.102.181.112   <none>          5556/TCP,5558/TCP                     172m
zadig-minio            ClusterIP      10.99.45.95      <none>          9000/TCP                              172m
zadig-mongodb          ClusterIP      10.98.252.235    <none>          27017/TCP                             172m
zadig-mysql            ClusterIP      10.101.122.76    <none>          3306/TCP                              172m
zadig-mysql-headless   ClusterIP      None             <none>          3306/TCP                              172m
zadig-portal           ClusterIP      10.104.141.49    <none>          80/TCP                                172m
```

我本地集群部署了 `<font style="color:#DF2A3F;">metalb</font>`，会自动为 `<font style="color:#DF2A3F;">gateway-proxy</font>` 服务分配一个 LoadBalancer 类型的 IP 地址，我们只需将 `<font style="color:#DF2A3F;">zadig.k8s.local</font>` 域名解析到该 IP 地址即可，然后我们就可以在浏览器中访问了。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347098284-d4e00cb0-d614-43ee-88d1-ba08b0dbd4a1.png)

默认的用户名为 `<font style="color:#DF2A3F;">admin</font>`，密码为 `<font style="color:#DF2A3F;">zadig</font>`，登录后即可进入首页。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347097428-deabf36e-2db2-4e22-8f60-950adf553277.png)

**架构**

由于 Zadig 里面的组件依赖非常多，所以有必要对其架构做一定的了解，对于该应用运维会有一定的帮助。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347099556-098a7f45-31a7-4f99-88a6-5790833d6f42.jpeg)

用户入口：

+ `zadig-portal`：Zadig 前端组件
+ `kodespace`：Zadig 开发者命令行工具
+ `Zadig Toolkit`：vscode 开发者插件

API 网关：

+ `<font style="color:#DF2A3F;">Gloo Edge</font>`：Zadig 的 API 网关组件
+ `<font style="color:#DF2A3F;">OPA</font>`：认证和授权组件
+ `<font style="color:#DF2A3F;">Dex</font>`：Zadig 的身份认证服务，用于连接其他第三方认证系统，比如 AD/LDAP/OAuth2/GitHub/..
+ `<font style="color:#DF2A3F;">User</font>`：用户管理，Token 生成

Zadig 核心业务：

+ `<font style="color:#DF2A3F;">Picket</font>`：数据聚合服务
+ `<font style="color:#DF2A3F;">Aslan</font>`：项目/环境/服务/工作流/构建配置/系统配置等系统功能
+ `<font style="color:#DF2A3F;">Policy</font>`：OPA 数据源，策略注册中心
+ `<font style="color:#DF2A3F;">Config</font>`：系统配置

Workflow Runner：

+ `<font style="color:#DF2A3F;">warpdrive</font>`：工作流引擎，负责 `<font style="color:#DF2A3F;">reaper</font>`、`<font style="color:#DF2A3F;">predator</font>` 实例的创建销毁等管理操作
+ `<font style="color:#DF2A3F;">reaper</font>`：负责执行单个工作流作业中的构建、测试等任务
+ `<font style="color:#DF2A3F;">predator</font>`：负责执行单个工作流作业中的镜像分发任务
+ `<font style="color:#DF2A3F;">plugins</font>`：工作流插件
    - `<font style="color:#DF2A3F;">Jenkins-plugin</font>`：用于触发 Jenkins job，显示状态和结果等
+ `<font style="color:#DF2A3F;">Cron</font>`：定时任务，包括环境的回收，K8s 资源的清理等
+ `<font style="color:#DF2A3F;">NSQ</font>`：消息队列（第三方组件）

数据平面：

+ `MongoDB`：业务数据数据库
+ `MySQL`：存储 dex 配置、用户信息的数据库

K8s 集群：Zadig 业务运行在各种云厂商的标准 K8s 集群之上

这里不得不吐槽下 Zadig 这些组件的命名方式了，压根就不知道这些组件干嘛用的

## 3 基本使用
Zadig 安装完成后，接下来我们以容器化 Nginx 为例来说明下 Zadig 的基本使用。

### 3.1 集成代码源
首先我们要去添加下代码源，比如常见的 GitHub、GitLab 等。

**GitHub**

要集成 GitHub 代码源首先需要进入 [https://github.com/settings/developers](https://github.com/settings/developers) 页面新建一个 `OAuth Apps`，其中应用名称可以随便命名，首页 URL 我们这里是 `http://zadig.k8s.local`，下面的 `callback URL` 比较重要，填写 `http://zadig.k8s.local/api/directory/codehosts/callback`。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347097928-04267471-c12b-41b9-9825-86be4277fe23.png)

应用创建成功后，GitHub 会返回应用的基本信息，点击 `Generate a new client secret` 生成 Client Secret。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347098224-dc8e1eb4-aa01-48d4-a1fb-0727860e839f.png)

将生成的 `Client ID` 与 `Client Secret` 记录下来，切换到 Zadig 系统，管理员依次点击`系统设置 -> 集成管理 -> 代码源集成`页面，然后点击添加按钮，在弹出的对话框中选择 `GitHub` 代码源，填上上面获取的 `Client ID` 和 `Client Secret` 信息。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347099364-4ae6173b-43ce-4d28-bd13-face923d9b52.jpeg)

然后点击`前往授权`按钮，点击后会自动跳转到 GitHub 的授权页面，需要我们进行认证授权，授权后会自动跳转会 Zadig 系统页面。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347099472-07744f30-2bc9-4800-9ae2-6fbfcb8bc863.jpeg)

**GitLab**

如果要集成 GitLab 代码源，同样需要去创建一个认证应用，前往 GitLab 应用管理页面 [http://git.k8s.local/-/profile/applications](http://git.k8s.local/-/profile/applications)。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347099570-99420642-7c92-4cad-883c-400ae0919c01.png)

这里我们需要新建一个应用，名称为 `Zadig`，其中 `Redirect URI` 为 `http://zadig.k8s.local/api/directory/codehosts/callback`，需要勾选 `api`、`read_user`、`read_repository`3 个权限。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347100055-1b0435ba-80b8-4254-a4c0-797a66eeaaad.png)

应用创建成功后，GitLab 会返回应用的相关信息，其中包括 `Application ID`、`Secret` 信息。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347100205-b88c4a10-3d93-4fcc-bb22-6bc683b5fe91.png)

然后一样的方式前往 Zadig 添加一个新的代码源，将 GitLab 相关信息填写到对话框中。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347100286-25a3389d-b700-4160-9b6b-57fb3c61bb7c.png)

然后点击`前往授权`按钮会自动跳转到 GitLab 页面进行授权认证。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347104769-c8597b1c-1e47-421f-9a57-5de6ffc33698.png)

确认授权后会自动跳转会 Zadig，正常情况下就可以看到添加的代码源了。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347107611-fbfbbd50-9cea-4715-9ebd-e1d10205d076.png)

### 3.2 集成镜像仓库
代码源集成完成后，接下来我们需要添加镜像仓库到 Zadig 中，支持集成阿里云 ACR、腾讯云 TCR、华为云 SWR、Amazon ECR、DockerHub、Harbor 等镜像仓库，我们这里来集成同 K8s 集群中部署的 Harbor 服务。

首先在 Harbor 中创建一个名为 `zadig` 的新项目，用来保存 Zadig 中构建的镜像。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347108361-4d961715-5ed7-4aab-bc90-324e2c68bcc8.png)

在 Zadig 系统 [http://zadig.k8s.local/v1/system/registry](http://zadig.k8s.local/v1/system/registry) 页面点击`新建`按钮，配置上我们的 Harbor 相关信息。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347109144-c557cf85-4c5d-43ce-92e8-95ca069b8805.jpeg)

由于我这里的 Harbor 服务是自签名的服务，为了方便我这里未开启 SSL 校验，然后点击`保存`按钮即可。

### 3.3 新建项目
我们这里通过一个简单的 Nginx 应用来进行说明，代码放置在 GitLab 上面，仓库地址为 [http://git.k8s.local/course/zadig-nginx-demo](http://git.k8s.local/course/zadig-nginx-demo)，仓库就包含一个 `Dockerfile` 和 `index.html` 文件。

```plain
from nginx:stable

add index.html /usr/share/nginx/html
```

代码源准备好后，接下来我们就可以去创建项目了，Zadig 中的项目包括工作流、环境、服务、构建、测试、版本等资源，用户在项目中可以进行服务开发、服务部署、集成测试、版本发布等操作。

前面项目列表开始新建项目，这里我们选择 `K8s YAML项目`类型。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347109839-218af9e0-fca6-4a01-968d-ffb009f9979f.png)

点击`立即新建`按钮，进入项目初始化向导，点击下一步开始创建服务：

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347110690-ef8d75a5-a13e-47cc-b116-e99ebbb23473.jpeg)

点击`下一步`开始新建一个服务，Zadig 中的服务可以理解为一组 Kubernetes 资源，比如 Service、Deployment 等等，也可以是一个 Helm Chart 包。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347111395-8eb3767e-6fc0-4956-8f88-b053a579041a.jpeg)

新建服务提供了 3 种方式：

+ **手工输入**：直接配置 K8s 的资源清单文件
+ **从代码库导入**：从代码仓库中同步服务的 K8s 资源清单文件
+ **使用模板新建**：基于 K8s YAML 模板或者从 K8s 中导入

由于我们这里的示例非常简单，就直接使用手工输入的方式来新建服务。如下所示，我们新建一个名为 `nginx` 的服务，在中间的 YAML 区域编写我们服务的资源清单文件。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347111951-a482b022-cdee-40bf-95f7-0bb81ad8f8a5.jpeg)

这里我只需要简单创建一个 Deployment 和 Service 资源即可，对应的资源清单文件如下所示：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
      version: '{{.nginxVersion}}'
  template:
    metadata:
      labels:
        app: nginx
        version: '{{.nginxVersion}}'
    spec:
      containers:
        - name: nginx
          image: harbor.k8s.local/zadig/nginx:stable
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
    version: '{{.nginxVersion}}'
spec:
  labelSelector:
    app: nginx
  type: NodePort
  ports:
    - name: http
      port: 80
      targetPort: 80
```

然后点击`保存`按钮，保存后会自动加载除系统变量、YAML 中的自定义变量以及服务组件，上面的 YAML 文件中我们添加了一个 `{{.nginxVersion}}` 变量，Zadig 会自动读取到该变量。

接下来在变量区域点击`添加构建`为我们的服务配置构建方式。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347111943-b5812c44-1871-4f94-a023-8a7699a596f0.png)

可以根据需要配置构建的环境，同时选择 GitLab 这个代码源，并选择我们前面的项目代码仓库以及分支。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347112794-6367c636-0c39-4625-88c4-c845fff0727a.png)

然后在下方可以配置通用构建脚本：

```shell
cd $WORKSPACE/zadig-nginx-demo
docker build -t $IMAGE -f Dockerfile .
docker push $IMAGE
```

其中的 `$IMAGE` 变量就是策略中定义的镜像，默认会使用前面添加的 Harbor 镜像仓库（配置成了**默认**），配置后点击`保存构建`即可。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347113580-340e93b6-e8ce-4368-be4a-2b291ef36f29.png)

可以看到已经关联上了上面创建的构建信息了。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347114511-1b4fd912-f52d-45fa-8951-1c82eb0d5724.png)

接下来点击`下一步`继续，在这一步中，系统会自动创建 2 套环境和 3 条工作流。2 套环境可分别用于日常开发环节和测试验收环节，3 条工作流也会自动绑定对应的环境以达到对不同环境进行持续交付的目的。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347115497-56163886-4771-43f0-a989-7f010bee214c.jpeg)

Zadig 会在 K8s 集群中创建两个名为 `nginx-demo-env-dev` 和 `nginx-demo-env-qa` 的命名空间。

```shell
$ kubectl get ns |grep nginx-demo
nginx-demo-env-dev   Active   23s
nginx-demo-env-qa    Active   23s
```

继续`下一步`进入工作流执行页面，在该页面可以看到创建的 3 条工作流，分别对应这不同的环境。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347115860-f8cb64e4-d186-403f-95e4-866bb9ab2996.jpeg)

比如我们现在选择 `nginx-demo-workflow-dev` 这条工作流来完成 dev 环境的持续交付，点击后面的`点击运行`按钮。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347116676-4d764335-ac09-4214-9805-b97c3632f5d7.jpeg)

根据实际需求选择要部署的服务以及对应代码分支，然后点击启动任务即可开始执行构建任务。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347117618-4b60fec0-edc9-4128-8590-6b62239f79a9.jpeg)

任务启动后我们也可以看到会去自动启动一个 Pod 来执行构建任务，这点和 Jenkins 的动态 Slave 基本一致的，当任务构建完成后也会自动销毁该 Pod。

```shell
$ kubectl get pods -n zadig
NAME                                               READY   STATUS    RESTARTS       AGE
dind-0                                             1/1     Running   0              16m
nginx-demo-workflow-dev-2-buildv2-szhrk--1-mn6dd   1/1     Running   0              8s
# ......
```

任务执行完成后会使用新构建的镜像 `harbor.k8s.local/zadig/nginx:20220711184844-1-main` 去替换掉前面我们配置的资源清单中的镜像地址，自动部署到 `nginx-demo-env-dev` 命名空间中。

```shell
$ kubectl get pods -n nginx-demo-env-dev
NAME                    READY   STATUS    RESTARTS   AGE
nginx-5d5c7f978-r2vkd   1/1     Running   0          30s
```

我们可以通过该服务的 NodePort 来访问 nginx 服务。

```shell
$ kubectl get svc -n nginx-demo-env-dev
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.96.32.211   <none>        80:31675/TCP   6m57s
$ curl 192.168.0.106:31675

<h1>
    Hello 优点知识（youdianzhishi.com）!
</h1>
```

同时 `dev` 环境中的镜像信息也自动更新成了上面构建的镜像信息。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347117787-4846354e-2c26-4f69-ab5d-365decbd2dcb.jpeg)

其他环境的服务交付和上面都是类似的，接下来我们来配置自动触发工作流和版本交付。

点击 `dev` 工作流配置按钮，进入工作流配置页面。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347118013-fcb8d280-99e2-4bab-957f-764dc08f46ad.png)

点击左侧的`触发器+`按钮开始添加触发器，然后勾选 `Webook` 来添加一个 Webhook 的触发器。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347118848-1b4dab3e-ed7d-4a15-8238-3cdd07bb02d1.png)

点击`添加配置`添加一个触发器，这里我们为 GitLab 代码库添加一个触发器，选择对应的代码库和分支等信息，添加后记得保存。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347120652-70826654-5e92-40a8-a46a-daf31bea234e.jpeg)

现在我们去 GitLab 代码仓库中创建一个 Pull Request，在处理合并的页面中会自动关联上对应的 Zadig 工作流状态。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347120662-5e2d9f71-52ab-4c50-93b9-78bb4baa9c89.png)

点击任务链接可以跳转到 Zadig 工作流信息页面。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347132390-f59b264a-7201-467a-aff0-f52d412b5c47.png)

当然当我们将这个 PR 合并到 main 分支上过后同样也会触发一次新的任务。

**交付**

接下来我们就可以来交付我们的应用了，由于默认情况下只创建了一个 `dev` 和 `qa` 的环境，现在我们来创建一个 `prod` 环境用于生产环境使用。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347122664-ec4b36b2-4d69-417e-a194-0657a15b63e0.png)

创建一个名为 `prod` 的环境，默认情况下会关联上 K8s 的一个命名空间，我们也可以提前创建该命名空间，然后手动去关联即可，然后记得选择对应的镜像仓库和服务。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347123289-c304f422-dd7f-4a99-8519-1f3a5893912e.png)

点击`立即创建`按钮即可创建该环境。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347124852-61f331e5-9c20-404d-b938-41582bb058dc.png)

现在我们可以去执行 `nginx-demo-ops-workflow` 这条工作流来部署应用到生产环境了。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347125665-d7c44783-9ca8-4ab7-bf24-fd3b1fb4d62e.png)

点击`执行`按钮即可开始配置该条工作流，这里选择 `prod` 环境，指定需要使用的镜像，此外我们还可以创建版本信息。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347126561-19569a64-eec2-41f4-8014-99d979bcf960.jpeg)

点击`启动任务`就会开始使用关联的服务来部署应用了，任务执行完成后可以看到相关信息。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347127037-42be5a23-4f50-487a-a934-0d9ac6aed365.png)

同样我们也可以在 K8s 集群中来查看对应的资源。

```shell
$ kubectl get pods -n nginx-demo-env-prod
NAME                     READY   STATUS    RESTARTS   AGE
nginx-778d4d9686-c8sqk   1/1     Running   0          3m36s
$ kubectl get svc -n nginx-demo-env-prod
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.105.209.71   <none>        80:31971/TCP   9m35s
$ curl http://192.168.0.106:31971

<h1>
    Hello 优点知识（youdianzhishi.com）!
</h1>
```

在版本管理中可以看到我们创建的所有版本。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347128314-b241907e-e2ce-4f20-9b10-11c77a102879.png)

同样我们也可以选择具体的一个版本重新进行部署。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347128868-98c28b2a-f860-4eb5-8148-f8900d4b1f49.png)

到这里我们就使用 Zadig 完成了一个最简单的应用交付。

## 4 微服务交付
前面我们介绍的是一个非常简单的示例，接下来我们来介绍下微服务项目如何在 Zadig 下进行交付。

我们这里使用到开源项目是 [https://github.com/GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)，该开源项目名叫 [Online Boutique](https://onlineboutique.dev/)，是一个云原生微服务演示应用程序，其中包含 11 个微服务，该应用程序是一个基于 Web 的电子商务应用程序，用户可以在其中浏览商品、将它们添加到购物车并购买它们。

该项目由 11 个使用不同语言编写的微服务组成，它们通过 gRPC 相互通信。架构如下所示。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347129205-fdb98ac2-bb73-4ee6-b6bd-3bf51a8f10b1.jpeg)

每个服务的功能描述如下表所示。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347128966-91248d0e-39e6-425d-b085-21efb83d0dfe.png)

接下来我们来使用 Zadig 来交付该微服务项目，使用方式和前面基本类似。

首先新建一个名为 `microservices-demo` 的项目，项目类型为 `K8s YAML 项目`。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347129158-991dc3b5-be1e-4021-8a91-c294898e0c70.png)

点击`立即新建`按钮，然后进入项目初始化页面。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347129863-6f94cc4f-41a4-48de-af26-9ce3bbe194d2.jpeg)

点击`下一步`进入到服务配置页面，我们知道服务模板可以通过手动创建、代码仓库中同步或者现有 K8s 资源中导入而来。我们这里服务模板在代码仓库中，所以选择从代码库中进行同步，选择对应的代码仓库、分支和对应的资源清单目录，然后点击`同步`按钮即可将对应的服务同步到 Zadig 中来。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347129845-cacb307d-bde8-495c-9389-67b277b398fe.jpeg)

可以看到我们这里同步过来后包含了 12 个服务，每个服务的模板也都直接展示出来了，但是由于是通过仓库同步的，模板是只读模式，右侧会自动读取到服务对应的镜像信息。

注意：Zadig 读取资源清单后，**会以 K8s YAML 中的容器名作为唯一的 key 进行去重**（也算是一个 BUG 吧），所以在编写 K8s YAML 的时候不要让容器名重复，否则导入后会丢失服务。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347130034-5f6880bb-3786-4ceb-8097-56c5b7af1384.jpeg)

点击右侧读取到的镜像服务组件后面的`添加构建`按钮，前往配置该服务的镜像是如何进行构建的。

首先需要添加服务代码源信息，我们这里的代码在 GitLab 上面，所以添加对应的代码仓库以及分支信息。我们这里的所有服务代码都位于代码仓库根目录下面的 `src` 目录下。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347130280-a9e80033-299e-41f6-bc19-1634eeb7e485.png)

这属于典型的 `Monorepo` 类型的仓库（单体），而里面的每个服务我们也并未配置成 `submodule`，所以每个服务构建的时候均要将整个代码仓库 Clone 下来，但其实我们只需要其中的一个服务即可，Git 是支持这种操作的，比如我们现在只想要获取 `adservice` 这个服务的数据，可以通过下面的方式来获取。

```shell
$ mkdir microservices-demo && cd microservices-demo
$ git init
$ git remote add origin git@git.k8s.local:course/microservices-demo.git
$ git config core.sparsecheckout true
$ git sparse-checkout set "src/adservice"
$ git pull --depth 1 origin main
remote: Enumerating objects: 307, done.
remote: Counting objects: 100% (307/307), done.
remote: Compressing objects: 100% (234/234), done.
remote: Total 307 (delta 72), reused 185 (delta 39), pack-reused 0
Receiving objects: 100% (307/307), 9.55 MiB | 5.28 MiB/s, done.
Resolving deltas: 100% (72/72), done.
From git.k8s.local:course/microservices-demo
 * branch            main       -> FETCH_HEAD
 * [new branch]      main       -> origin/main
$ ls -la src
total 0
drwxr-xr-x   3 cnych  staff   96 Jul 15 14:10 .
drwxr-xr-x   4 cnych  staff  128 Jul 15 14:10 ..
drwxr-xr-x  12 cnych  staff  384 Jul 15 14:10 adservice
```

通过上面的方式可以只获取指定目录的代码，但是遗憾的是 Zadig 目前并不支持该功能，或许后续会支持吧！

代码源配置后，最主要的是添加**通用构建脚本**。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347130437-79680f74-222e-4e55-b337-639617e5b471.png)

我们这里其实就是配置如何构建镜像，对应的脚本如下所示：

```shell
#!/bin/bash
set -e

cd $WORKSPACE/$REPONAME_0/src/adservice

docker build -t $IMAGE -f Dockerfile .

docker push $IMAGE
```

首先需要进入到当前服务的代码根目录下面，我们这里使用的是 `cd $WORKSPACE/$REPONAME_0/src/adservice` 命令，其中的 `$WORKSPACE`、`$REPONAME_0`、`$IMAGE` 均为内置的构建变量，`$WORKSPACE` 表示工作根目录，而 `$REPONAME_0` 表示配置的第一个代码仓库的名称，也就是 `microservices-demo`。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347130570-d7d1b090-4bf4-4f00-961c-1bc64192c7b8.png)

进入到服务根目录下面后，我们只需要执行 `docker build` 命令构建镜像即可，每个服务的根目录下面均配置了 `Dockerfile` 文件，构建的镜像使用变量 `$IMAGE` 代替，会使用添加的默认的镜像仓库。

默认的镜像命名规则如下所示，我们也可以自行定制。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347130681-2b6fba7f-48fc-4ce2-8ba6-59e5e42b3f7d.png)

构建配置完过后，记得`保存构建`，用同样的方式配置所有服务的构建。

服务配置完成后下一步开始加入环境，同样默认情况下会自动创建一套 dev 和 qa 的环境以及 3 条工作流。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347131043-66a74a78-89ce-454d-b58f-6af4b38120ea.jpeg)

加入环境后就可以看到对应的 3 条工作流了，点击`完成`即可。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347131096-b8782abd-ab36-4f97-ba82-4813e2453059.jpeg)

这样项目就创建成功了，现在我们先在 dev 环境来运行工作流。点击`执行`工作流，在服务中可以选择我们要构建的服务，可以选择一个也可以选择多个服务。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347131299-bed71269-2800-4faa-870f-abc587ce09dc.jpeg)

同样任务执行后会执行配置的通用脚本，然后将对应的服务部署到 K8s 集群中去。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347131437-bc6dc544-7fed-4528-9fbf-f1ef997e8920.jpeg)

将所有的服务执行完成后在环境页面可以看到所有服务的状态和最新镜像信息。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347131937-e8c89297-e935-4cd3-a3d9-f786eb6478f3.jpeg)

每个服务都正常部署到 dev 环境后，查看对应的 Pod 状态：

```shell
$ kubectl get pods -n microservices-demo-env-dev
NAME                                     READY   STATUS    RESTARTS   AGE
adservice-5b5b97cf59-b7d6g               1/1     Running   0          21m
cartservice-7d66bd5c4-wxd6v              1/1     Running   0          15m
checkoutservice-6dbc8cdc46-fqrnx         1/1     Running   0          14m
currencyservice-54fccf7b9f-c29h5         1/1     Running   0          13m
emailservice-844b6c9b58-j5smc            1/1     Running   0          13m
frontend-649699cc5-s5ggp                 1/1     Running   0          12m
loadgenerator-565cdbb5dc-6dtrb           1/1     Running   0          5m42s
paymentservice-fd8f95f79-4889n           1/1     Running   0          11m
productcatalogservice-775db476b6-l4s2t   1/1     Running   0          6m47s
recommendationservice-79f558bc9b-jx69n   1/1     Running   0          6m47s
redis-cart-f9bdd7959-qtc9n               1/1     Running   0          34m
shippingservice-f789c4494-ktbnz          1/1     Running   0          6m43s
$ kubectl get svc -n microservices-demo-env-dev
NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE
adservice               ClusterIP      10.96.40.23      <none>         9555/TCP       41m
cartservice             ClusterIP      10.110.0.136     <none>         7070/TCP       41m
checkoutservice         ClusterIP      10.109.209.29    <none>         5050/TCP       41m
currencyservice         ClusterIP      10.98.43.229     <none>         7000/TCP       41m
emailservice            ClusterIP      10.101.67.47     <none>         5000/TCP       41m
frontend                ClusterIP      10.96.37.222     <none>         80/TCP         41m
frontend-external       LoadBalancer   10.109.168.181   192.168.0.53   80:30090/TCP   41m
paymentservice          ClusterIP      10.105.223.48    <none>         50051/TCP      41m
productcatalogservice   ClusterIP      10.102.112.64    <none>         3550/TCP       41m
recommendationservice   ClusterIP      10.99.127.143    <none>         8080/TCP       41m
redis-cart              ClusterIP      10.111.15.205    <none>         6379/TCP       41m
shippingservice         ClusterIP      10.104.122.207   <none>         50051/TCP      41m
```

该服务最后是通过 `frontend-external` 这个 LoadBalancer 类型的 Service 来暴露的服务，我们可以直接通过分配的 IP `192.168.0.53` 来访问服务了。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347132044-9591577d-ecac-4399-9c0a-16d756247bc9.png)

同样我们也可以给服务添加触发器来触发任务，在工作流编辑页面点击左侧的`触发器`添加，勾选 `Webhook` -> `添加配置`，我们可以先添加一个只针对 `adservice` 这个服务的触发器，选择对应的代码库、要部署的服务，最关键的是文件目录部分的配置，也就是代码仓库中的什么文件变更才会触发我们的任务，我们的配置为：

```shell
src/adservice/
!.md
!.gitignore
```

该段配置的表示当代码仓库中 `src/adservice/` 目录下面的代码有变更，并且不是 `.md` 或者 `.gitignore` 文件则会触发任务。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347132054-c76fd6e9-bca9-4ad8-82bc-f034858d9ce8.jpeg)

配置后记得保存。现在我们可以去修改下 `adservice` 服务中的代码，修改代码 `src/adservice/src/main/java/hipstershop/AdService.java`，比如我们将 177 行的 50%修改为 60%，然后提交代码到 main 分支。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347132523-5153e79d-2057-4c8d-a526-83e40ec03939.png)

当我们将上述代码 push 到 main 分支后，Zadig 就立即触发了一次新的任务。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347132877-48623c57-8a1f-4f64-8e8f-bd2f2623e231.png)

该任务执行成功后我们可以去查看该产品的页面是否生效。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347132911-7aa87394-6691-4e66-8687-af4cbd55807c.png)

到这里我就实现了该微服务项目的持续构建，同样的我们可以去手动创建一个环境来进行交付，操作方式一样的。

此外我们还可以来新建一些测试用例，在测试页面点击`新建测试`按钮即可开始创建测试用例。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347136521-2e44e7b5-5fb2-4550-8873-6490806afd66.png)

比如我们这里对一个 go 服务做一次简单的测试，在依赖的软件包中可以选择对应的依赖，如果没有对应的软件包，则可以新建一个。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347137248-cf75956c-1e70-4e64-b878-75486253cf51.png)

比如我们需要一个 1.17 版本的 go 环境，可以通过 `系统设置 -> 软件包管理` 新建一个软件包。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347137990-06a2e8f8-4b33-4393-9f72-b028bfa9a81a.jpeg)

然后我们重新去创建一个测试用例，选择相应的依赖，同样配置对应的代码源和测试脚本。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347138301-468f184f-db54-4336-ace1-bf657c1e51dd.png)

创建后可以用同样的方式来执行该测试用例。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347138285-afa95899-7441-4ff6-a97a-43ea1d2e7ab9.png)

测试详情页面和工作流的任务页面基本上一致。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347139442-e788880a-49f4-410a-822a-f37f34019c23.jpeg)

同样也可以看到对应的测试报告。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347139862-cfb5ce34-e773-4145-9721-ad84e7079f03.jpeg)

此外我们还可以将自动化测试和工作流关联起来，当日常运行工作流更新环境后，会自动执行自动化测试。可以实现只要环境有变更，就第一时间对其做自动化测试。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347139902-448bf617-793e-4be6-8ce7-c65d73933906.png)

关联后启动工作流任务就可以看到有该测试用例了。

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347140316-98948d12-a23b-4d20-a686-66681ecf5e1a.jpeg)

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734347140711-879421d5-3b76-4438-ab46-1a215eb3ebcf.jpeg)

Zadig 还会为我们的构建数据进行统计，提供构建效能、部署效能等数据。

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734347141219-cf4f300f-1a27-4658-9818-838171663597.png)

到这里我们就完成了使用 Zadig 来对微服务项目进行持续集成和交付，当然在实际的生产环境中和具体的项目业务有关系，这就需要能够结合实际需求去实践了。

