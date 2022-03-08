# 第四章：K8s管理应用生命周期-Deployment篇

## 1.创建一个deployment副本数为3,然后滚动更新镜像版本,并记录这个更新记录,最后再回滚到上一个版本

- 名称: nginx
- 镜像版本: 1.16
- 更新镜像版本: 1.17

### 答案

```bash
# 创建deploy,镜像nginx1.6,副本数3
kubectl create deployment nginx --image=nginx:1.16 --replicas=3

# 更新镜像版本到1.17,并对本次升级加上变化注解--记录这次更新
kubectl set image deployment/nginx nginx=nginx:1.17 --record

# 查看镜像是否为1.17
[master root ~]# kubectl describe deployment/nginx|grep -i image
                        kubernetes.io/change-cause: kubectl set image deployment/nginx nginx=nginx:1.17 --record=true
    Image:        nginx:1.17

# 查看rs
[master root ~]# kubectl get rs -owide
NAME               DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES       SELECTOR
nginx-6d4cf56db6   0         0         0       11m     nginx        nginx:1.16   app=nginx,pod-template-hash=6d4cf56db6
nginx-db749865c    3         3         3       4m30s   nginx        nginx:1.17   app=nginx,pod-template-hash=db749865c

# 查看deployment历史版本
[master root ~]# kubectl rollout history deployment 
deployment.apps/nginx 
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment/nginx nginx=nginx:1.17 --record=true

# 回滚到上一个版本,监视deployment的滚动升级状态直到完成
[master root ~]# kubectl rollout undo deployment nginx && kubectl rollout status -w deployment nginx
deployment.apps/nginx rolled back
Waiting for deployment "nginx" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
deployment "nginx" successfully rolled out

# 查看deploy/nginx的镜像版本
[master root ~]# kubectl describe deployments.apps nginx|grep -i image
    Image:        nginx:1.16
```





## 2. 给deploy/web扩容副本数为3

### 答案

```bash
# 创建deploy/web
kubectl create deployment web --image=nginx

# 扩容副本数为3
kubectl scale deployment web --replicas=3

# 查看有几个pod
[master root ~]# kubectl get po
NAME                  READY   STATUS    RESTARTS   AGE
web-96d5df5c8-c6xcs   1/1     Running   0          2m42s
web-96d5df5c8-kslrm   1/1     Running   0          109s
web-96d5df5c8-xhv5n   1/1     Running   0          109s
```



## 3.把deploy输出为json文件,再删除创建的deploy

### 答案

```bash
# 把deploy/web输出为json文件
[master root ~]# kubectl get deployments.apps web -ojson> dep.json

# 根据json删除这个deploy
[master root ~]# kubectl delete -f dep.json 
deployment.apps "web" deleted

# 查看这个dep还在不在
[master root ~]# kubectl get deployments.apps 
No resources found in aliang-cka namespace.
```

## 4.生成一个deploy的yaml文件保存到/opt/deploy.yaml

- 名称:web
- 标签: app_env_stage=dev

### 答案

```bash
# 生成yaml文件
kubectl create deployment web --image=nginx -oyaml --dry-run > /opt/deploy.yaml 
```

修改后的yaml文件

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
    app_env_stage: dev
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
      app_env_stage: dev
  template:
    metadata:
      labels:
        app: web
        app_env_stage: dev
    spec:
      containers:
      - image: nginx
        name: nginx
```

