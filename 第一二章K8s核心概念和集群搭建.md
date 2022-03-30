---
title: 第一二章K8s核心概念和集群搭建
date: 2022-03-30 12:15:51
tags: k8s
---


## 1. 搭建一个k8s集群

```bash
[master root ~]# kubectl get no -owide
NAME     STATUS   ROLES                  AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE                           KERNEL-VERSION                CONTAINER-RUNTIME
master   Ready    control-plane,master   13d   v1.22.7   192.168.123.200   <none>        Rocky Linux 8.5 (Green Obsidian)   5.4.180-1.el8.elrepo.x86_64   docker://20.10.12
node     Ready    <none>                 13d   v1.22.7   192.168.123.220   <none>        Rocky Linux 8.5 (Green Obsidian)   5.4.180-1.el8.elrepo.x86_64   docker://20.10.12
```



## 2.新建一个命名空间，创建一个deployment并暴露Service  

- 命名空间： aliang-cka
- 名称： web
- 镜像： nginx  

### 答案:

```bash
# 新建一个命名空间
kubectl create namespace aliang-cka

# 使用kubens切换到aliang-cka这个命名空间
kubens aliang-cka

# 新建deployment
kubectl create deployment web --image=nginx

# 查看web这个deployment创建成功没有
[master root ~]# kubectl get deployments.apps web 
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    1/1     1            1           7m23s
[master root ~]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
web-96d5df5c8-pj8cg   1/1     Running   0          7m30s

# 暴露一个服务
kubectl expose deployment web --port=80 --target-port=80 --type=NodePort

# 访问验证
[master root ~]# curl 10.83.28.128|grep title
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   615  100   615    0     0   300k      0 --:--:-- --:--:-- --:--:--  300k
<title>Welcome to nginx!</title>
```



## 3.列出命名空间下指定标签pod

命名空间: kube-system

标签: k8s-app=kube-dns

### 答案

```bash
# 查询pod,-n=kube-system,-l=k8s-app=kube-dns
[master root ~]# kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS      AGE
coredns-78fcd69978-8kjtl   1/1     Running   1 (10d ago)   12d
coredns-78fcd69978-jkxkd   1/1     Running   1 (10d ago)   12d

# 查看完整标签
[master root ~]# kubectl get po -n kube-system -l k8s-app=kube-dns --show-labels 
NAME                       READY   STATUS    RESTARTS      AGE   LABELS
coredns-78fcd69978-8kjtl   1/1     Running   1 (10d ago)   12d   k8s-app=kube-dns,pod-template-hash=78fcd69978
coredns-78fcd69978-jkxkd   1/1     Running   1 (10d ago)   12d   k8s-app=kube-dns,pod-template-hash=78fcd69978
```