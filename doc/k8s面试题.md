---
title: 遇到的k8s面试题
date: 2022-03-11 11:25:51
tags: k8s
---







## 硬驱逐和软驱逐

### 答:

参考: [硬驱逐条件和软驱逐条件](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/node-pressure-eviction/#soft-eviction-thresholds)

[kubernetes-pod驱逐机制](https://www.cnblogs.com/yaohong/p/13245723.html)

1、硬驱逐：没有宽限期,硬驱逐条件时， kubelet 会立即杀死 pod
2、软驱逐：有宽限期, 在超过宽限期之前，kubelet 不会驱逐 Pod。



![image-20220311125648437](k8s%E9%9D%A2%E8%AF%95%E9%A2%98/image-20220311125648437.png)

## deployment如何像daemonset一样每个node运行一个

### 答:

用`pod反亲和`可以实现.



## svc和endpoint的区别

### 答:

#### svc工作原理:

svc是通过标签选择pod.

#### endpoint工作原理:

endpoint是监听svc选择的pod的ip.通过kube-proxy来轮询访问pod.



## ansible中include 和 import的区别

参考: [ansible中include 和 import的区别](https://www.cnblogs.com/leffss/p/14632423.html#include%E5%92%8Cimport%E5%8C%BA%E5%88%AB)

### 答:

`ansible` 目前有 `import_tasks`、`include_tasks`、`import_playbook`、`include_playbook`、`import_role`、`include_role`

`import` 和 `include` 区别相近：
**区别一**

- `import_tasks(Static)`方法会在`playbooks`解析阶段将`父task变量`和`子task变量`全部读取并加载
- `include_tasks(Dynamic)`方法则是在执行`play`之前才会`加载自己变量`

**区别二 **

- `include_tasks`方法调用的文件名称可以加变量

- `import_tasks`方法调用的文件名称不可以有变量

**具体参考：https://www.cnblogs.com/mauricewei/p/10054041.html**

也正是因为「include_task」是动态导入，当我们给「include_role」导入的role打tag时，实际并不会执行该role的task。



## RUN,CMD,ENTRYPOINT的区别

参考 [RUN,CMD,ENTRYPOINT的区别](https://www.jianshu.com/p/f0a0f6a43907)

- `RUN`命令执行命令并创建新的镜像层，通常用于安装软件包
- `CMD`命令设置容器启动后默认执行的命令及其参数，但CMD设置的命令能够被docker run命令后面的命令行参数替换
- `ENTRYPOINT`配置容器启动时的执行命令（不会被忽略，一定会被执行，即使运行 docker run时指定了其他命令）