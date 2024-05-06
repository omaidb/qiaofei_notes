---
title: 第三章：K8s监控与日志
date: 2022-03-30 12:45:50
tags: k8s
---

## 1.查看pod日志,并将日志中Eoor的行记录到指定文件

- pod名称: web
- 文件: /opt/web

### 答案:

```bash
kubectl logs web-96d5df5c8-pj8cg |grep -i error > /opt/web
```



## 2.查看指定标签使用cpu最高的pod,并记录到指定文件

- 标签: app=web
- 文件: /opt/cpu

### 答案

#### 先部署`metric-server服务`

```bash
# 下载metric-server服务
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 重命名yaml文件
mv components.yaml metric-server.yaml

# 修改yaml文件,在容器参数中添加忽略证书
## 添加忽略证书
- --kubelet-insecure-tls

# apply这个yaml
kubectl apply -f metric-server.yaml 

# 验证是否注册到apiservers,结果必须为True
kubectl get apiservices.apiregistration.k8s.io |grep metrics

# 查看所有namespace下的pod的资源使用率,并按照cpu排序
[master root ~/k8s-yaml]# kubectl top pod -l app=web --sort-by="cpu" -A
NAMESPACE    NAME                  CPU(cores)   MEMORY(bytes)   
aliang-cka   web-96d5df5c8-pj8cg   0m           3Mi          

# 将结果写入到文件
[master root ~/k8s-yaml]# kubectl top pod -l app=web --sort-by="cpu" -A > /opt/cpu
```

