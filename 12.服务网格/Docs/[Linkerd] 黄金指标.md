<font style="color:rgb(28, 30, 33);">在上一章中，我们了解了使用 CLI 部署 Linkerd 控制平面和 Linkerd-viz 扩展，并在几分钟内收集指标是多么容易。在本章中，我们将详细了解这些指标，并使用 </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> 示例应用程序了解它们的含义。</font>

<font style="color:rgb(28, 30, 33);">我们先简单了解下服务健康黄金指标的经典定义：</font>

+ <font style="color:rgb(28, 30, 33);">Latency（延迟）</font>
+ <font style="color:rgb(28, 30, 33);">Error rate（错误率）</font>
+ <font style="color:rgb(28, 30, 33);">Traffic volume（流量）</font>
+ <font style="color:rgb(28, 30, 33);">Saturation（饱和度）</font>

<font style="color:rgb(28, 30, 33);">Linkerd 的价值不仅仅在于它可以提供这些指标，毕竟，我们可以非常简单地直接检测应用程序代码。相反，Linkerd 的价值在于它可以在整个应用程序中以统一的方式提供这些指标，并且不需要更改应用程序代码。换句话说，无论是谁编写的，它使用什么框架，它是用什么语言编写的，以及它做什么，Linkerd 都可以为你的服务提供这些指标。</font>

<font style="color:rgb(28, 30, 33);">接下来让我们来依次检查下黄金指标，看看 Linkerd 是如何测量它们的。</font>

**<font style="color:rgb(28, 30, 33);">Latency</font>**

<font style="color:rgb(28, 30, 33);">延迟是响应请求所需的时间，对于 Linkerd，是通过 Linkerd 代理向应用程序发送请求和接收响应之间经过的时间来进行衡量的，因为它在请求之间可能会有很大差异，所以指定时间段的延迟通常作为统计分布来衡量，并报告为此分布的百分位数。Linkerd 能够报告常用的延迟指标例如 p50、p95、p99 和 p999，对应于 50、95、99 和 99.9 的百分位数。请求的延迟分布，这些被称为“尾部延迟”，通常是报告大规模系统行为的重要指标。</font>

**<font style="color:rgb(28, 30, 33);">Error rate</font>**

<font style="color:rgb(28, 30, 33);">错误率是被视为错误响应的百分比，对于 Linkerd，是通过 HTTP 状态码来衡量的：</font>`<font style="color:rgb(28, 30, 33);">2xx</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">4xx</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">响应被认为是成功的，</font>`<font style="color:rgb(28, 30, 33);">5xx</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">响应被认为是失败的，当然反过来我们也可以说 Linkerd 报告的是成功率而不是错误率。</font>

<font style="color:rgb(28, 30, 33);">需要注意虽然</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">4xx</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">HTTP 响应码对应于各种形式的“未找到您请求的资源”，但这些是服务器方面的正确响应，而不是错误响应。因此，Linkerd 认为这些请求是成功的，因为</font>**<font style="color:rgb(28, 30, 33);">服务器按照它的要求做了</font>**<font style="color:rgb(28, 30, 33);">。</font>

**<font style="color:rgb(28, 30, 33);">Traffic volume</font>**

<font style="color:rgb(28, 30, 33);">流量是对系统的需求量度，在 Linkerd 的上下文中，这被测量为请求率，例如每秒请求数 (RPS)。Linkerd 简单地通过计算它代理到应用程序的请求来计算这一点。</font>

<font style="color:rgb(28, 30, 33);">另外也需要注意由于 Linkerd 可以自动重试请求，因此它提供了两种流量度量：</font>**<font style="color:rgb(28, 30, 33);">实际（对应请求，包括重试）</font>**<font style="color:rgb(28, 30, 33);">和</font>**<font style="color:rgb(28, 30, 33);">有效（对应不重试的请求）</font>**<font style="color:rgb(28, 30, 33);">。如果客户端向中间有 Linkerd 的服务器发出请求，则有效计数将是客户端发出的请求数；实际计数将是服务器收到的请求数。</font>

**<font style="color:rgb(28, 30, 33);">Saturation</font>**

<font style="color:rgb(28, 30, 33);">饱和度是对服务可用的总资源消耗的度量，例如 CPU、内存。与其他服务网格一样，Linkerd 没有直接的机制来衡量饱和度，但是，延迟通常是一个很好的近似值。</font>[<font style="color:rgb(28, 30, 33);">谷歌 SRE 书籍</font>](https://landing.google.com/sre/sre-book/chapters/monitoring-distributed-systems/#saturation)<font style="color:rgb(28, 30, 33);">说：</font>

延迟增加通常是饱和的主要指标，在某个小窗口（例如一分钟）内测量你的第 99 个百分位响应时间可以给出非常早期的饱和信号。

<font style="color:rgb(28, 30, 33);">所以我们这里主要使用另外三个黄金指标：成功率、请求率和延迟。</font>

<font style="color:rgb(28, 30, 33);">最后一点是，虽然 Linkerd 可以代理任何 TCP 流量，但这些黄金指标仅适用于使用 HTTP 或 gRPC 的服务。这是因为这些指标需要第 7 层或协议级别的理解才能计算。一个 HTTP 请求具有成功和不成功请求的概念，任意的 TCP 字节流不会。</font>

## <font style="color:rgb(28, 30, 33);">Linkerd Dashboard 中查看指标</font>
<font style="color:rgb(28, 30, 33);">上面我们了解了这些指标，接下来我们再来看看前面部署的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用。</font>

```shell
$ kubectl get pods -n emojivoto
NAME                        READY   STATUS    RESTARTS        AGE
emoji-696d9d8f95-5vn9w      2/2     Running   2 (5h11m ago)   41h
vote-bot-6d7677bb68-jvxsg   2/2     Running   2 (5h11m ago)   41h
voting-ff4c54b8d-jjpkm      2/2     Running   2 (5h11m ago)   41h
web-5f86686c4d-58p7k        2/2     Running   2 (5h11m ago)   41h
```

`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用是一个 gRPC 服务，一共包含三个微服务：</font>

+ <font style="color:rgb(28, 30, 33);">web：用户与之交互的前端服务</font>
+ <font style="color:rgb(28, 30, 33);">emoji：提供表情列表的 API 服务</font>
+ <font style="color:rgb(28, 30, 33);">voting：提供为表情投票的 API 服务</font>

<font style="color:rgb(28, 30, 33);">我们已经将该应用引入到网格中来了，能够在 Linkerd 仪表板中查看</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用的指标了，当我们打开 Viz 的仪表板的时候，默认会显示集群的所有命名空间列表，其中有一个非常大的区别是命名空间列表中的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">项目现在在</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Meshed</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">列下显示为 4/4。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575408860-0a7ea249-17dd-4094-b3bf-c397be7bc9c0.png)

<font style="color:rgb(28, 30, 33);">单击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">链接可查看命名空间的详细信息，包括“章鱼”图，显示服务如何通过网络连接相互关联的。请记住这张图片，因为我们将使用 CLI 工具查看相同的信息。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575408492-3cc2c70d-8ccb-45c7-96e6-073f3e0d419e.png)

<font style="color:rgb(28, 30, 33);">此外还可以看到我们上面讨论过的黄金指标：p50、p95 和 p99 延迟、服务的成功/错误率以及请求量，即每秒请求数(RPS)。从成功率一列可以看出其中一项服务有一些错误。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575408576-e10a84a8-b3e2-45c0-b5eb-7d37acf47b65.png)

<font style="color:rgb(28, 30, 33);">该 Deployment 级别信息是处理应用程序请求的所有 Pod 的指标的聚合，我们向下滚动页面的时候，可以看到每个 Pod 对应的指标。我们可以通过增加 web 服务的副本数来进行验证。</font>

<font style="color:rgb(28, 30, 33);">执行下面的命令将 web 服务增加到两个副本：</font>

```shell
$ kubectl scale deploy/web -n emojivoto --replicas=2
```

<font style="color:rgb(28, 30, 33);">执行此命令后，仪表板将自行更新，Web 应用将在</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Meshed</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">列下显示为 2/2，此外，你将在 Pod 部分下看到另一个 Web pod。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575408479-62778c66-1733-4de1-9942-832c0cbe35c7.png)

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575408411-ef9fdf10-8436-4542-a3c9-95edc6f0ed01.png)

<font style="color:rgb(28, 30, 33);">通过观察 Deployments 和 Pods 部分的数据，可以看到 Deployments 中的指标数据的确就是 Pods 的指标聚合数据。最后我们再来看看 Linkerd 提供的 TCP 级别的指标，在</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间的页面底部，会显示 TCP 连接数以及每个 Pod 读取和写入的字节数。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575409413-87d54e90-291a-4f8b-9c98-be477b10e901.png)

<font style="color:rgb(28, 30, 33);">TCP 的指标比 7 层的指标会更少，例如在任意 TCP 字节流中没有请求的概念。尽管如此，这些指标在调试应用程序的连接级别问题时仍然很有用。</font>

<font style="color:rgb(28, 30, 33);">接下来我们将继续探索仪表板并查看让我们实时查看流量的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">功能。</font>`<font style="color:rgb(28, 30, 33);">Tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">是 Linkerd2 的一个非常有特色的功能，它可以随时抓取某资源的实时流量，有效的利用该功能可以非常方便的监控服务的请求流量情况，协助调试服务。</font>

<font style="color:rgb(28, 30, 33);">到目前为止，我们已经可以使用仪表板来获取</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用程序中服务的聚合性能指标了。现在让我们使用仪表板通过 Linkerd 提供的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">功能实时查看流量。</font>

<font style="color:rgb(28, 30, 33);">在仪表板中，我们可以看到</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务的成功率低于 100%，让我们使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">功能来查看对服务的请求，来尝试弄清楚发生了什么。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575409154-28be1634-bb84-4fed-bf4d-5231490ba0a1.png)

<font style="color:rgb(28, 30, 33);">单击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">应用的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">链接可以深入了解详细信息，我们将看到的第一件事是显示</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">微服务与应用程序中其他微服务之间关系的图表。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575409423-5eaf3b59-ee4f-4337-9750-5c8a5f6b6dbc.png)

<font style="color:rgb(28, 30, 33);">在图表下方，我们可以看到一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">LIVE CALLS</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的选项卡，其中显示了对</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务的实时调用！每次调用时，表中的行都会更新有关请求的相关信息，包括响应的 HTTP 状态。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575409519-4c149b28-dd9d-4a47-ade2-9a16d36553c8.png)

<font style="color:rgb(28, 30, 33);">在我们详细了解这些实时调用之前，我们可以点击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Route Metrics</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">选项卡来查看</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务的路由表以及每个路由的指标，在我们这里只有一个名为</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Default</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的路由，它是为每个服务创建的。在后面的章节中我们将介绍服务配置文件以及将它们添加到应用程序后会如何影响此选项卡的显示。现在，我们只需要知道此选项卡存在就足够了。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575409726-43d36865-8949-48bb-8e29-09bc27681492.png)

<font style="color:rgb(28, 30, 33);">现在我们知道了如何在仪表板中查找实时调用，现在我们来尝试下看看是否可以找到其中一个失败的调用并使用仪表板中的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">功能。当我们看到对路径</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">/emojivoto/v1.VotingService/VoteDoughnut</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的请求，请单击其右侧的显微镜图标跳转到 Tap 页面。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575409850-04714ddf-9a5b-49e3-953d-38ae27009bae.png)

<font style="color:rgb(28, 30, 33);">其实通过查看成功率这一列的数据很容易发现该路径请求有错误。</font>

<font style="color:rgb(28, 30, 33);">Tap 页面包含一个多个字段的表单，这些字段已根据我们点击的特定请求的链接预先填充了，比如我们这里 Path、Namespace、Resource 等字段都已经被自动填充上了，下面还有一个输出显示正在运行的当前</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">查询。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575410433-ed543130-17e4-4172-8ca7-1a6f99db3e8e.png)

<font style="color:rgb(28, 30, 33);">现在我们点击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">页面顶部的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">START</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">按钮，开始对投票服务的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">/emojivoto.v1.VotingService/VoteDougNut</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">路径的请求，几秒钟后，下方的列表将开始填充</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">VoteDougNut</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">路径的传入请求。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575410182-7a6663ef-50fe-4948-a06f-713d30e0d2cd.png)

<font style="color:rgb(28, 30, 33);">我们可以单击左侧的箭头来查看包含请求信息的对话框。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575410688-6776aec8-c18f-454d-a957-8117dc80a65d.png)

<font style="color:rgb(28, 30, 33);">这就是通过 Linkerd 仪表板中使用 Tap 的方式，我们还可以继续更改表单字段中的值并使用不同的查询来查看不同的请求，例如我们可以将</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Path</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">字段中的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">/emojivoto.v1.VotingService/VoteDoughnut</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">值删掉，并将</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">To Resource</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">设置为</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Deployment</font>`<font style="color:rgb(28, 30, 33);">，当我们点击开始按钮后，我们将可以看到从 Web 服务发送的所有流量。</font>

<font style="color:rgb(28, 30, 33);">现在我们已经知道如何使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">查看服务的流量指标，接下来让我们通过查看 Linkerd 的 Grafana 仪表板来了解这些指标是如何使用的。</font>

## <font style="color:rgb(28, 30, 33);">Grafana 中展示指标</font>
<font style="color:rgb(28, 30, 33);">Linkerd 的 Viz 插件内置了 Grafana，Linkerd 使用 Grafana 为部署到 Kubernetes 的应用程序添加了额外的可观察性数据。在浏览仪表板时，你可能已经注意到了 Grafana 图标，这里我们以</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">微服务为例对 Grafana 图表进行说明。</font>

<font style="color:rgb(28, 30, 33);">在 Linkerd 仪表板的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间中，单击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">行最右侧列中的 Grafana 图标，会打开 Grafana 仪表板以显示</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">微服务的相关图表，这些页面上的图表显示了 Linkerd 仪表板中显示的指标的时间序列数据，这里我们看到的就是</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务随着时间推移的服务性能变化。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575411151-22a837ab-4db0-4b9f-be03-68d66cc481a9.png)

<font style="color:rgb(28, 30, 33);">Grafana 仪表板上的图表包括我们的标准黄金指标集：</font>

+ <font style="color:rgb(28, 30, 33);">Success rate</font>
+ <font style="color:rgb(28, 30, 33);">Request rate</font>
+ <font style="color:rgb(28, 30, 33);">Latencies</font>

<font style="color:rgb(28, 30, 33);">随时间查看黄金指标图表的能力是了解应用程序性能的非常强大的工具。以时间序列的形式查看这些指标可以让你了解，例如，当流量负载增加时服务的执行情况，或者在进行更新以添加功能或修复错误时，服务的一个版本与另一个版本的比较情况。</font>

<font style="color:rgb(28, 30, 33);">Grafana 仪表板的优点在于你无需执行任何操作即可创建它们，Linkerd 使用动态模板为每个注入 Linkerd 代理和部分服务网格的 Kubernetes 资源生成仪表板和图表。我们可以在 Grafana 仪表板的左上角，单击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Linkerd Deployment</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">链接以打开可用仪表板列表。</font>

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1735575411033-e08b1459-4ed4-4df9-908f-1de5df836e82.jpeg)

<font style="color:rgb(28, 30, 33);">比如我们可以点击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Linkerd Pod</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">仪表盘，查看与</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务相关的一个 Pod 的图表，仪表板中显示了单个 Pod 的相同的黄金指标，这与 Deployment 仪表板不同，因为 Deployment 仪表板显示了与 Deployment 相关的所有 Pod 的汇总指标。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575411579-743bec31-1363-4915-816d-7c29b7122388.png)

## <font style="color:rgb(28, 30, 33);">Linkerd CLI 命令查看指标</font>
<font style="color:rgb(28, 30, 33);">Linkerd 仪表板功能很强大，因为它在基于浏览器的界面中显示了大量指标，如果你不想使用浏览器的话，那么我们可以使用 Linkerd CLI 命令行工具，CLI 在终端中提供了仪表板相同的功能。</font>

<font style="color:rgb(28, 30, 33);">我们可以使用如下所示的命令来显示</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间中从 Web 服务通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">/emojivoto.v1.VotingService/VoteDoughnut</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">路径到投票服务的所有流量：</font>

```shell
$ linkerd viz tap deployment/web --namespace emojivoto --to deployment/voting --path /emojivoto.v1.VotingService/VoteDoughnut
req id=3:0 proxy=out src=10.244.2.71:41226 dst=10.244.1.95:8080 tls=true :method=POST :authority=voting-svc.emojivoto:8080 :path=/emojivoto.v1.VotingService/VoteDoughnut
rsp id=3:0 proxy=out src=10.244.2.71:41226 dst=10.244.1.95:8080 tls=true :status=200 latency=1128µs
end id=3:0 proxy=out src=10.244.2.71:41226 dst=10.244.1.95:8080 tls=true grpc-status=Unknown duration=183µs response-length=0B
# ......
```

<font style="color:rgb(28, 30, 33);">此外我们还通过使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">-o json</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">标志指定输出数据为 JSON 格式，以获取更多详细信息，如下所示：</font>

```shell
$ linkerd viz tap deployment/web --namespace emojivoto --to deployment/voting --path /emojivoto.v1.VotingService/VoteDoughnut -o json
{
  "source": {
    "ip": "10.244.1.108",
    "port": 59370,
    "metadata": {
      "control_plane_ns": "linkerd",
      "deployment": "web",
      "namespace": "emojivoto",
      "pod": "web-5f86686c4d-58p7k",
      "pod_template_hash": "5f86686c4d",
      "serviceaccount": "web",
      "tls": "loopback"
    }
  },
  "destination": {
    "ip": "10.244.1.95",
    "port": 8080,
    "metadata": {
      "control_plane_ns": "linkerd",
      "deployment": "voting",
      "namespace": "emojivoto",
      "pod": "voting-ff4c54b8d-jjpkm",
      "pod_template_hash": "ff4c54b8d",
      "server_id": "voting.emojivoto.serviceaccount.identity.linkerd.cluster.local",
      "service": "voting-svc",
      "serviceaccount": "voting",
      "tls": "true"
    }
  },
  "routeMeta": null,
  "proxyDirection": "OUTBOUND",
  "responseInitEvent": {
    "id": {
      "base": 6,
      "stream": 6
    },
    "sinceRequestInit": {
      "nanos": 686968
    },
    "httpStatus": 200,
    "headers": [
      {
        "name": ":status",
        "valueStr": "200"
      },
      {
        "name": "content-type",
        "valueStr": "application/grpc"
      },
      {
        "name": "grpc-status",
        "valueStr": "2"
      },
      {
        "name": "grpc-message",
        "valueStr": "ERROR"
      },
      {
        "name": "date",
        "valueStr": "Thu, 25 Aug 2022 08:52:05 GMT"
      }
    ]
  }
}
# ......
```

<font style="color:rgb(28, 30, 33);">可以看到 JSON 输出的信息要详细得多，因为每个请求都会打印有关的多行信息，包括：</font>

+ <font style="color:rgb(28, 30, 33);">HTTP 方法</font>
+ <font style="color:rgb(28, 30, 33);">流量的方向</font>
+ <font style="color:rgb(28, 30, 33);">HTTP Header</font>

<font style="color:rgb(28, 30, 33);">让我们再运行一个更粗粒度的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">查询，就像我们在仪表板中运行的查询一样。比如获取 Web 服务的所有流量：</font>

```shell
$ linkerd viz tap deploy/web -n emojivoto
req id=7:13 proxy=out src=10.244.1.108:33416 dst=10.244.1.88:8080 tls=true :method=POST :authority=emoji-svc.emojivoto:8080 :path=/emojivoto.v1.EmojiService/FindByShortcode
rsp id=7:13 proxy=out src=10.244.1.108:33416 dst=10.244.1.88:8080 tls=true :status=200 latency=708µs
end id=7:13 proxy=out src=10.244.1.108:33416 dst=10.244.1.88:8080 tls=true grpc-status=OK duration=35µs response-length=20B
req id=7:14 proxy=out src=10.244.1.108:59370 dst=10.244.1.95:8080 tls=true :method=POST :authority=voting-svc.emojivoto:8080 :path=/emojivoto.v1.VotingService/VoteMan
rsp id=7:14 proxy=out src=10.244.1.108:59370 dst=10.244.1.95:8080 tls=true :status=200 latency=809µs
end id=7:14 proxy=out src=10.244.1.108:59370 dst=10.244.1.95:8080 tls=true grpc-status=OK duration=65µs response-length=5B
# ......
```

<font style="color:rgb(28, 30, 33);">上面的命令我们删除了</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">--to</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">--path</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">这些参数，粒度更粗了，整个输出将显示所有进出 Web 服务的流量，包括</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">web</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务以及</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">web</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务之间的流量。</font>

<font style="color:rgb(28, 30, 33);">我们可以根据每行输出中的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">src</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">dst</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">字段查看流量的方向，我们也可以尝试使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">-o json</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">标志再次运行查询以查看 JSON 格式的输出，并查看是否可以发现给定请求的流量方向。</font>

<font style="color:rgb(28, 30, 33);">上面我们了解了如何在终端中使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令实时显示流量，我们还可以使用另外一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd viz top</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令，该命令和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">tap</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令提供相同的信息，但格式与基于 Unix 的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">top</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令相同。换句话说，</font>`<font style="color:rgb(28, 30, 33);">linkerd viz top</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">显示了按最受欢迎的路径排序的流量路线，我们来执行如下所示的命令进行查看：</font>

```shell
$ linkerd viz top deploy/web -n emojivoto
```

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1735575412040-1810bf19-c941-478b-8b69-01094727dfe0.png)

<font style="color:rgb(28, 30, 33);">同样现在我们想在终端中查看仪表板中看到的延迟、成功/错误率和每秒请求数指标，又应该怎么操作呢？同样 Linkerd CLI 提供了一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">stat</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令可以帮助我们来执行该操作。让我们通过获取</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间中所有服务的指标来尝试一下，如下所示：</font>

```shell
$ linkerd viz stat deploy -n emojivoto
NAME       MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
emoji         1/1   100.00%   2.3rps           1ms           1ms           1ms          4
vote-bot      1/1   100.00%   0.3rps           1ms           1ms           1ms          1
voting        1/1    89.74%   1.3rps           1ms           1ms           1ms          4
web           2/2    93.51%   2.6rps           1ms           7ms           9ms          6
```

`<font style="color:rgb(28, 30, 33);">linkerd viz stat</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令可以获取到应用服务性能的最新指标数据，如果你想要获取更多数据，可以添加</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">-o wide</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">标志来获取这些 TCP 级别的详细信息。</font>

<font style="color:rgb(28, 30, 33);">任何时候您想要获得应用程序中服务性能的最新快照，您都可以使用 linkerd viz stat 来获取这些指标。如果您想更深入地获取写入和读取的字节数，可以添加 -o Wide 标志来获取这些 TCP 级别的详细信息。无论是否使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">-o wide</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">标志，都将始终显示 TCP 连接。</font>

```shell
$ linkerd viz stat deploy -n emojivoto -o wide
NAME       MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN   READ_BYTES/SEC   WRITE_BYTES/SEC
emoji         1/1   100.00%   2.3rps           1ms           1ms           1ms          4         229.0B/s         2680.8B/s
vote-bot      1/1   100.00%   0.3rps           1ms           3ms           3ms          1          24.3B/s          585.0B/s
voting        1/1    89.74%   1.3rps           1ms           1ms           1ms          4         121.4B/s          481.0B/s
web           2/2    92.95%   2.6rps           1ms           4ms           4ms          6         205.0B/s         5949.4B/s
```

<font style="color:rgb(28, 30, 33);">同样</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">stat</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令也可以通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">--to</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">参数来缩小查询范围，比如我们想要查询从</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">web</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务到</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务的流量，可以使用如下所示的命令：</font>

```shell
$ linkerd viz stat -n emojivoto deploy/web --to deploy/voting
NAME   MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
web       2/2    86.67%   1.0rps           1ms           4ms           4ms          2
```

<font style="color:rgb(28, 30, 33);">可以看到输出的数据和前面一张，只是只有一行数据输出，其中最值得注意的是，成功率这一列低于 100% 了。从这个输出中，我们可以推断出，当我们查看</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命名空间中的所有服务时，</font>`<font style="color:rgb(28, 30, 33);">web</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务的成功率是来自</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务响应的总和。为了验证这个假设，让我们再运行一 个查询，以仅查看从</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">web</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务到命名空间中所有其他服务的流量。</font>

```shell
$ linkerd viz stat -n emojivoto deploy --from deploy/web
NAME     MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
emoji       1/1   100.00%   1.9rps           1ms           1ms           2ms          2
voting      1/1    83.05%   1.0rps           1ms           1ms           2ms          2
```

<font style="color:rgb(28, 30, 33);">在这里我们可以看到，实际上，</font>`<font style="color:rgb(28, 30, 33);">voting</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务存在错误，而</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">emoji</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">服务则没有。</font>

`<font style="color:rgb(28, 30, 33);">stat</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令是一个功能强大的工具，具有许多配置选项。我们可以运行</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">linkerd viz stat -h</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">以查看可以运行</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">stat</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的所有可用方式。</font>

<font style="color:rgb(28, 30, 33);">上面我们介绍了几种不同的方式来查看被 Linkerd 网格化的应用的黄金指标数据。接下来我们将学习如何使用服务配置文件获取每个路由的指标，通过为 Kubernetes 服务创建 </font>`<font style="color:rgb(28, 30, 33);">ServiceProfile</font>`<font style="color:rgb(28, 30, 33);"> 对象，我们可以指定服务可用的路由并为每个路由收集单独的指标。到目前为止，我们只能看到 </font>`<font style="color:rgb(28, 30, 33);">default</font>`<font style="color:rgb(28, 30, 33);"> 路由上对服务的所有请求的指标。为 </font>`<font style="color:rgb(28, 30, 33);">emojivoto</font>`<font style="color:rgb(28, 30, 33);"> 服务配置 </font>`<font style="color:rgb(28, 30, 33);">ServiceProfiles</font>`<font style="color:rgb(28, 30, 33);"> 后，我们将能够看到每条路由的指标！</font>

