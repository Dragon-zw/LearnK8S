<font style="color:rgb(28, 30, 33);">Gitlab 官方提供了 Helm 的方式在 Kubernetes 集群中来快速安装，但是官方提供的 Helm Chart 包（</font>[<font style="color:rgb(28, 30, 33);">https://charts.gitlab.io/）非常复杂，也需要一个域名来绑定</font>](https://charts.gitlab.io/%EF%BC%89%E9%9D%9E%E5%B8%B8%E5%A4%8D%E6%9D%82%EF%BC%8C%E4%B9%9F%E9%9C%80%E8%A6%81%E4%B8%80%E4%B8%AA%E5%9F%9F%E5%90%8D%E6%9D%A5%E7%BB%91%E5%AE%9A)<font style="color:rgb(28, 30, 33);"> GitLab 实例，所以我们这里使用自定义的方式来安装，也就是自己来定义一些资源清单文件。</font>

<font style="color:rgb(28, 30, 33);">Gitlab 主要涉及到 3 个应用：Redis、Postgresql、Gitlab 核心程序，实际上我们只要将这 3 个应用分别启动起来，然后加上对应的配置就可以很方便的安装 Gitlab 了，我们这里选择使用的镜像不是官方的，而是 Gitlab 容器化中使用非常多的一个第三方镜像：</font>`<font style="color:rgb(28, 30, 33);">sameersbn/gitlab</font>`<font style="color:rgb(28, 30, 33);">，基本上和官方保持同步更新，地址：</font>[<font style="color:rgb(28, 30, 33);">http://www.damagehead.com/docker-gitlab/</font>](http://www.damagehead.com/docker-gitlab/)

## <font style="color:rgb(28, 30, 33);">部署</font>
<font style="color:rgb(28, 30, 33);">如果我们已经有可使用的 Redis 或 Postgresql 服务的话，那么直接配置在 Gitlab 环境变量中即可，如果没有的话就单独部署,我们这里为了展示 gitlab 部署的完整性，还是分开部署。</font>

<font style="color:rgb(28, 30, 33);">首先部署需要的 Redis 服务，对应的资源清单文件如下：</font>

```yaml
# gitlab-redis.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: kube-ops
  labels:
    name: redis
spec:
  selector:
    matchLabels:
      name: redis
  template:
    metadata:
      name: redis
      labels:
        name: redis
    spec:
      containers:
        - name: redis
          image: sameersbn/redis:4.0.9-3
          imagePullPolicy: IfNotPresent
          ports:
            - name: redis
              containerPort: 6379
          volumeMounts:
            - mountPath: /var/lib/redis
              name: data
          livenessProbe:
            exec:
              command:
                - redis-cli
                - ping
            initialDelaySeconds: 30
            timeoutSeconds: 5
          readinessProbe:
            exec:
              command:
                - redis-cli
                - ping
            initialDelaySeconds: 30
            timeoutSeconds: 1
      volumes:
        - name: data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: kube-ops
  labels:
    name: redis
spec:
  ports:
    - name: redis
      port: 6379
      targetPort: redis
  selector:
    name: redis
```

<font style="color:rgb(28, 30, 33);">然后是数据库 Postgresql，对应的资源清单文件如下，为了提高数据库的性能，我们这里也没有使用共享存储之类的，而是直接用的 Local PV 将应用固定到一个节点上：</font>

```yaml
# gitlab-postgresql.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgresql-pvc
  namespace: kube-ops
spec:
  storageClassName: local-path
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: kube-ops
  labels:
    name: postgresql
spec:
  selector:
    matchLabels:
      name: postgresql
  template:
    metadata:
      name: postgresql
      labels:
        name: postgresql
    spec:
      containers:
        - name: postgresql
          image: sameersbn/postgresql:12-20200524
          imagePullPolicy: IfNotPresent
          env:
            - name: DB_USER
              value: gitlab
            - name: DB_PASS
              value: passw0rd
            - name: DB_NAME
              value: gitlab_production
            - name: DB_EXTENSION
              value: pg_trgm,btree_gist
            - name: USERMAP_UID
              value: '999'
            - name: USERMAP_GID
              value: '999'
          ports:
            - name: postgres
              containerPort: 5432
          volumeMounts:
            - mountPath: /var/lib/postgresql
              name: data
          readinessProbe:
            exec:
              command:
                - pg_isready
                - -h
                - localhost
                - -U
                - postgres
            initialDelaySeconds: 30
            timeoutSeconds: 1
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: postgresql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: kube-ops
  labels:
    name: postgresql
spec:
  ports:
    - name: postgres
      port: 5432
      targetPort: postgres
  selector:
    name: postgresql
```

<font style="color:rgb(28, 30, 33);">然后就是我们最核心的 Gitlab 的应用，对应的资源清单文件如下：(gitlab.yaml)</font>

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitlab-pvc
  namespace: kube-ops
spec:
  storageClassName: local-path
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab
  namespace: kube-ops
  labels:
    name: gitlab
spec:
  selector:
    matchLabels:
      name: gitlab
  template:
    metadata:
      name: gitlab
      labels:
        name: gitlab
    spec:
      initContainers:
        - name: fix-permissions
          image: busybox:1.35.0
          command: ['sh', '-c', 'chown -R 1000:1000 /home/git/data']
          securityContext:
            privileged: true
          volumeMounts:
            - name: data
              mountPath: /home/git/data
      containers:
        - name: gitlab
          image: sameersbn/gitlab:15.1.0
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: Asia/Shanghai
            - name: GITLAB_TIMEZONE
              value: Beijing
            - name: GITLAB_SECRETS_DB_KEY_BASE
              value: long-and-random-alpha-numeric-string
            - name: GITLAB_SECRETS_SECRET_KEY_BASE
              value: long-and-random-alpha-numeric-string
            - name: GITLAB_SECRETS_OTP_KEY_BASE
              value: long-and-random-alpha-numeric-string
            - name: GITLAB_ROOT_PASSWORD
              value: admin321
            - name: GITLAB_ROOT_EMAIL
              value: 517554016@qq.com
            - name: GITLAB_HOST
              value: git.k8s.local
            - name: GITLAB_PORT
              value: '80'
            - name: GITLAB_NOTIFY_ON_BROKEN_BUILDS
              value: 'true'
            - name: GITLAB_NOTIFY_PUSHER
              value: 'false'
            - name: GITLAB_BACKUP_SCHEDULE
              value: daily
            - name: GITLAB_BACKUP_TIME
              value: 01:00
            - name: DB_TYPE
              value: postgres
            - name: DB_HOST
              value: postgresql
            - name: DB_PORT
              value: '5432'
            - name: DB_USER
              value: gitlab
            - name: DB_PASS
              value: passw0rd
            - name: DB_NAME
              value: gitlab_production
            - name: REDIS_HOST
              value: redis
            - name: REDIS_PORT
              value: '6379'
          ports:
            - name: http
              containerPort: 80
            - name: ssh
              containerPort: 22
          volumeMounts:
            - mountPath: /home/git/data
              name: data
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 60
            timeoutSeconds: 1
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: gitlab-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: gitlab
  namespace: kube-ops
  labels:
    name: gitlab
spec:
  ports:
    - name: http
      port: 80
      targetPort: http
  selector:
    name: gitlab
---
apiVersion: apisix.apache.org/v2beta2
kind: ApisixRoute
metadata:
  name: gitlab
  namespace: kube-ops
spec:
  http:
    - name: main
      match:
        hosts:
          - git.k8s.local
        paths:
          - '/*'
      backends:
        - serviceName: gitlab
          servicePort: 80
```

<font style="color:rgb(28, 30, 33);">同样因为我们这里的 gitlab 镜像内部是一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">git</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的用户（id=1000），所以我们这里为了持久化数据通过一个 initContainers 将我们的数据目录权限进行更改：</font>

```yaml
initContainers:
  - name: fix-permissions
    image: busybox
    command: ['sh', '-c', 'chown -R 1000:1000 /home/git/data']
    securityContext:
      privileged: true
    volumeMounts:
      - name: data
        mountPath: /home/git/data
```

<font style="color:rgb(28, 30, 33);">由于 gitlab 启动非常慢，也非常消耗资源，我们同样还是用的 Local PV，为了不让应用重启，我们这里也直接去掉了 livenessProbe，这样可以防止 gitlab 自动重启，要注意的是其中 Redis 和 Postgresql 相关的环境变量配置，另外，我们这里添加了一个 ApisixRoute 对象，来为我们的 Gitlab 配置一个域名</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">git.k8s.local</font>`<font style="color:rgb(28, 30, 33);">，这样应用部署完成后，我们就可以通过该域名来访问了，然后直接部署即可：</font>

```shell
$ kubectl apply -f gitlab-redis.yaml gitlab-postgresql.yaml gitlab.yaml
```

<font style="color:rgb(28, 30, 33);">创建完成后，查看 Pod 的部署状态：</font>

```shell
$ kubectl get pods -n kube-ops
NAME                                           READY     STATUS    RESTARTS   AGE
gitlab-7d855554cb-twh7c                        1/1       Running   0          10m
postgresql-8566bb959c-2tnvr                    1/1       Running   0          17h
redis-8446f57bdf-4v62p                         1/1       Running   0          17h
```

<font style="color:rgb(28, 30, 33);">可以看到都已经部署成功了，然后我们可以通过 Ingress 中定义的域名</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">git.k8s.local</font>`<font style="color:rgb(28, 30, 33);">(需要做 DNS 解析或者在本地</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">/etc/hosts</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">中添加映射)来访问 Portal：</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734346621565-d427512a-4640-46f8-a7b1-e26c77aba713.png)

<font style="color:rgb(28, 30, 33);">使用用户名</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">root</font>`<font style="color:rgb(28, 30, 33);">，和部署的时候指定的超级用户密码</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">GITLAB_ROOT_PASSWORD=admin321</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">即可登录进入到首页：</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734346622373-57459f9c-c322-438c-adbb-b96258e68baa.png)

<font style="color:rgb(28, 30, 33);">进入首页后可以看到有一个安全提示</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Anyone can register for an account.</font>`<font style="color:rgb(28, 30, 33);">，现在可以注册账号，我们可以点击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Turn off</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">按钮去关掉该功能。</font>

<font style="color:rgb(28, 30, 33);">在首页也可以看到默认系统中有一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">GitLab Instance/Monitoring</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的项目，该项目是自动生成来帮助监控 GitLab 实例的。</font>

## <font style="color:rgb(28, 30, 33);">创建项目</font>
<font style="color:rgb(28, 30, 33);">Gitlab 运行后，我们可以注册为新用户并创建一个项目，还可以做很多的其他系统设置，比如设置语言、设置应用风格样式等等。</font>

<font style="color:rgb(28, 30, 33);">点击</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Create a project</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">创建一个新的项目，和 Github 使用上没有多大的差别：</font>

![](https://cdn.nlark.com/yuque/0/2024/jpeg/2555283/1734346622770-225f543e-8717-4fec-a891-9b1847f9f992.jpeg)

<font style="color:rgb(28, 30, 33);">创建完成后，我们可以添加本地用户的一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">SSH-KEY</font>`<font style="color:rgb(28, 30, 33);">，这样我们就可以通过</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">SSH</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">来拉取或者推送代码了。SSH 公钥通常包含在</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">~/.ssh/id_rsa.pub</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">文件中，并以</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">ssh-rsa</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">开头。如果没有的话可以使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">ssh-keygen</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">命令来生成，</font>`<font style="color:rgb(28, 30, 33);">id_rsa.pub</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">里面的内容就是我们需要的 SSH 公钥，然后添加到 Gitlab 中。</font>

<font style="color:rgb(28, 30, 33);">如果我们通过 SSH 方式去获取代码，这里需要注意我们服务的暴露方式，我们这里是通过 Apisix 来暴露的服务，属于 7 层服务，而且我们这里本地是通过 LoadBalancer 去接入的 Ingress 流量。</font>

```shell
$ kubectl get svc apisix-gateway -n apisix
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                      AGE
apisix-gateway   LoadBalancer   10.99.192.59   192.168.0.100   80:32661/TCP,443:30161/TCP   3d
```

<font style="color:rgb(28, 30, 33);">默认情况下 ssh 协议是通过 22 端口去进行访问的，即便我们是直接通过节点去暴露的服务也不能用默认的（会和节点冲突），所以我们这里单独配置一个 NodePort 类型的 ssh 服务，我们通过该端口去访问，如下所示：</font>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: gitlab-ssh
  namespace: kube-ops
  labels:
    name: gitlab
spec:
  ports:
    - name: ssh
      port: 22
      targetPort: ssh
      nodePort: 30022
  type: NodePort
  selector:
    name: gitlab
```

<font style="color:rgb(28, 30, 33);">注意上面 ssh 对应的 nodePort 端口设置为 30022，这样就不会随机生成了，注意同样要在 Deployment 中去配置下面的两个环境变量：</font>

```yaml
- name: GITLAB_SSH_HOST # 设置ssh host
  value: '192.168.0.106'
- name: GITLAB_SSH_PORT # 设置 ssh port
  value: '30022'
```

<font style="color:rgb(28, 30, 33);">重新更新下 Deployment 和 Service，更新完成后，现在我们在项目上面 Clone 的时候使用 ssh 就会带上端口号了：</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734346619206-033800ba-4aee-41f3-b6f2-11cb54942921.png)

<font style="color:rgb(28, 30, 33);">现在就可以使用</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">Clone with SSH</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的地址了，由于上面我们配置了 SSH 公钥，所以就可以直接访问上面的仓库了：</font>

```shell
$ git clone ssh://git@192.168.0.106:30022/root/gitlab-demo.git
Cloning into 'gitlab-demo'...
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[192.168.0.106]:30022' (ED25519) to the list of known hosts.

remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (3/3), done.
```

<font style="color:rgb(28, 30, 33);">然后随便在该项目下面添加一些资源：</font>

```shell
$ echo "# hello world" >  README.md
$ git add .
$ git commit -m "change README"
[master 1023f85] change README
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push origin main
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 10 threads
Compressing objects: 100% (1/1), done.
Writing objects: 100% (3/3), 257 bytes | 257.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To ssh://192.168.0.106:30022/root/gitlab-demo.git
   275bd83..25191c5  main -> main
```

<font style="color:rgb(28, 30, 33);">然后刷新浏览器，就可以看到刚刚创建的 Git 仓库中多了一个</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">README.md</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">的文件：</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734346620830-377fc80d-56a7-47d4-8d48-6958c966cb1b.png)

<font style="color:rgb(28, 30, 33);">到这里就表明我们的 GitLab 就成功部署到了 Kubernetes 集群当中了。</font>

<font style="color:rgb(28, 30, 33);">如果你觉得现在这样去 Clone 的时候需要 IP 和端口的形式不太友好，那么有办法变成直接使用域名的方式吗？首先我们要考虑的是通过域名的方式就用通过 Apisix 来做代理，前面直接创建的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">ApisixRoute</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">属于 7 层，肯定是不行的，但实际上除了 HTTP 之外， Apisix 也支持代理 TCP 服务。</font>

<font style="color:rgb(28, 30, 33);">这里我们更新前面我们 Apisix 章节中部署的应用，添加一个 TCP 端口用于代理我们的 SSH 请求，注意下面的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">gateway.stream.tcp</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">我们添加了一个 22 的端口：</font>

```yaml
# ci/prod-ssh.yaml
apisix:
  enabled: true

  image:
    repository: cnych/apisix
    tag: py3-plugin-2.10.0-alpine

  tolerations:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
      operator: Exists

  nodeSelector: # 固定在master1节点上
    kubernetes.io/hostname: master1

extPlugins:
  enabled: true
  cmds: ['python3', '/apisix-python-plugin-runner/apisix/main.py', 'start']

gateway:
  type: LoadBalancer
  annotations:
    lb.kubesphere.io/v1alpha1: openelb
    protocol.openelb.kubesphere.io/v1alpha1: layer2
    eip.openelb.kubesphere.io/v1alpha2: eip-pool
  externalTrafficPolicy: Cluster
  http:
    enabled: true
    servicePort: 80
    containerPort: 9080
  stream:
    enabled: true
    tcp: [22]
    udp: []
  tls:
    enabled: true # 启用 tls
    servicePort: 443
    containerPort: 9443

# etcd configuration
etcd:
  enabled: true
  replicaCount: 1

dashboard:
  enabled: true

ingress-controller:
  enabled: true
  config:
    apisix:
      serviceName: apisix-admin
      serviceNamespace: apisix # 指定命名空间
```

<font style="color:rgb(28, 30, 33);">使用上面的 values 文件重新更新 Apisix：</font>

```shell
$ helm upgrade --install apisix ./apisix -f ./apisix/ci/prod2.yaml -n apisix --create-namespace
Release "apisix" has been upgraded. Happy Helming!
NAME: apisix
LAST DEPLOYED: Tue Jul  5 16:09:28 2022
NAMESPACE: apisix
STATUS: deployed
REVISION: 7
NOTES:
1. Get the application URL by running these commands:
     NOTE: It may take a few minutes for the LoadBalancer IP to be available.
           You can watch the status of by running 'kubectl get --namespace apisix svc -w apisix-gateway'
  export SERVICE_IP=$(kubectl get svc --namespace apisix apisix-gateway --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo http://$SERVICE_IP:80
(env4hyy) ➜  manifests kubectl get pods -n apisix
NAME                                         READY   STATUS        RESTARTS      AGE
apisix-6bddcf88f6-q4cmp                      1/1     Terminating   0             8m16s
apisix-9f65cc58c-lzzsn                       1/1     Running       0             62s
apisix-dashboard-b69d5c768-rtt97             1/1     Running       2 (24h ago)   25h
apisix-etcd-0                                1/1     Running       2 (25h ago)   3d
apisix-ingress-controller-7d5bbf5dd5-p5wbf   1/1     Running       0             49m
$ kubectl get svc -n apisix
NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                     AGE
apisix-admin                ClusterIP      10.103.192.62   <none>          9180/TCP                                    3d
apisix-dashboard            ClusterIP      10.102.34.48    <none>          80/TCP                                      3d
apisix-etcd                 ClusterIP      10.98.100.194   <none>          2379/TCP,2380/TCP                           3d
apisix-etcd-headless        ClusterIP      None            <none>          2379/TCP,2380/TCP                           3d
apisix-gateway              LoadBalancer   10.99.192.59    192.168.0.100   80:32661/TCP,443:30161/TCP   3d
apisix-ingress-controller   ClusterIP      10.100.157.27   <none>          80/TCP
```

<font style="color:rgb(28, 30, 33);">由于我们现在的域名是解析到上面的 LoadBalancer 上面的，那么显然我们需要在</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">apisix-gateway</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">这个 Service 上新增一个 ssh 的访问端口，然后关联到上面的 apisix 的 22 端口上去。</font>

```shell
$ kubectl edit svc apisix-gateway -n apisix
# ......
spec:
  # ......
  ports:
  - name: apisix-gitlab-ssh
    nodePort: 32330
    port: 22
    protocol: TCP
    targetPort: 1022
  - name: apisix-gateway
    nodePort: 32661
    port: 80
    protocol: TCP
    targetPort: 9080
  - name: apisix-gateway-tls
    nodePort: 30161
    port: 443
    protocol: TCP
    targetPort: 9443
  selector:
    app.kubernetes.io/instance: apisix
    app.kubernetes.io/name: apisix
  sessionAffinity: None
  type: LoadBalancer
```

<font style="color:rgb(28, 30, 33);">修改后如下所示：</font>

```shell
$ kubectl get svc -n apisix apisix-gateway
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                                   AGE
apisix-gateway   LoadBalancer   10.99.192.59   192.168.0.100   22:32330/TCP,80:32661/TCP,443:30161/TCP   3d
```

<font style="color:rgb(28, 30, 33);">创建一个专门用 gitlab ssh 代理的 ApisixRoute 对象：</font>

```yaml
apiVersion: apisix.apache.org/v2beta2
kind: ApisixRoute
metadata:
  name: gitlab-ssh
  namespace: kube-ops
spec:
  stream:
    - name: ssh
      protocol: TCP
      match:
        ingressPort: 22
      backend:
        serviceName: gitlab
        servicePort: 22
```

<font style="color:rgb(28, 30, 33);">将 Deployment 中的</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">GITLAB_SSH_HOST</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">和</font><font style="color:rgb(28, 30, 33);"> </font>`<font style="color:rgb(28, 30, 33);">GITLAB_SSH_PORT</font>`<font style="color:rgb(28, 30, 33);"> </font><font style="color:rgb(28, 30, 33);">去掉重新更新，更新后的 ssh 地址就不带端口了。</font>

![](https://cdn.nlark.com/yuque/0/2024/png/2555283/1734346622259-685cf260-18ae-4c85-ba9a-d3e84723cafb.png)

<font style="color:rgb(28, 30, 33);">然后重新 clone 就可以了：</font>

```shell
$ git clone ssh://git@git.k8s.local/root/gitlab-demo.git
Cloning into 'gitlab-demo'...
remote: Enumerating objects: 6, done.
remote: Counting objects: 100% (6/6), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 6 (delta 1), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (6/6), done.
Resolving deltas: 100% (1/1), done.
```

