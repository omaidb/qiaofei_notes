---
title: 第四章：K8s管理应用生命周期-Pod篇
date: 2022-03-30 12:45:51
tags: k8s
---

## 1.创建一个4容器pod

容器列表:

- nginx
- redis
- memcached
- consul

### 答案

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: test
  name: test
spec:
  containers:
  - image: nginx
    name: test
  - image: redis
    name: redis
  - image: memcached
    name: memcached
  - image: consul
    name: consul
```

apply这个yaml

```bash
kubectl apply -f pod.yaml 

# 查看pod状态
[master root ~]# kubectl get pod 
NAME   READY   STATUS    RESTARTS   AGE
test   4/4     Running   0          2m17s
```



## 2.在节点上配置kubelet托管启动一个pod

- 节点: node1
- pod名称: web
- 镜像: nginx

```bash
# ssh登录到node1
ssh node1

# 查看配置文件中的静态pod路径staticPodPath: /etc/kubernetes/manifests
cat /var/lib/kubelet/config.yaml

# 在staticPodPath中创建static-web.yaml
touch /etc/kubernetes/manifests/static-web.yaml
```

static-web.yaml文件示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  # 静态pod的名称
  name: static-web
  labels:
    # 标签
    role: myrole
spec:
  containers:
    # 容器名
    - name: web
      # 镜像名
      image: nginx
```

查看静态pod

```bash
[master root ~]# kubectl get po|grep -i static-web
static-web-node   1/1     Running   0          6m10s
```



### 3.检查容器中文件是否创建,如果没有被检测到pod重启--探针

- 文件路径: /tmp/test.sock

### 答案

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: test
  name: test
spec:
  containers:
  - image: nginx
    name: test
    args:
      - /bin/bash
      - -c
      - touch /tmp/test.sock; sleep 600; 
    livenessProbe:
      exec:
        command:
          - cat
          - /tmp/test.sock
      initialDelaySeconds: 0
      periodSeconds: 1
```

