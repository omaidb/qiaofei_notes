## 1. 创建一个pod,分配到指定标签node上

- pod名: web
- 镜像: nginx
- node标签: disk=ssd

### 答案

```bash
# 给node打标签
kubectl label node n2 disk=ssd
```

`kubectl run web --image=nginx -oyaml --dry-run >1.yaml`创建yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: web
  name: web
spec:
  containers:
  - image: nginx
    name: web
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disk: ssd
```

`kubectl apply -f 1.yaml`创建pod

```bash
# 查看pod运行是否运行在n2节点
[m1 root ~]# kubectl get po -owide
NAME   READY   STATUS    RESTARTS   AGE     IP              NODE   NOMINATED NODE   READINESS GATES
web    1/1     Running   0          2m41s   100.104.217.1   n2     <none>           <none>
```



## 2.确保每个节点上运行一个pod

- pod名称: nginx
- 镜像: nginx

### 答案

```bash

```

## 3.查看集群中状态为ready的node数量,并将结果写到指定文件

### 答案:

```bash
# 查看nodes状态()
[m1 root ~]# kubectl describe nodes|grep -i taint
Taints:             <none>
Taints:             <none>
Taints:             <none>
Taints:             <none>

# 写入结果
echo 4 >/nodes_num.txt
```

