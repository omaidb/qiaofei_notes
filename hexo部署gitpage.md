---
title: hexo部署gitpage
date: 2022-02-22 22:14:32
tags:
---



参考: https://hexo.io/zh-cn/docs/setup

https://qlzhu.github.io/blog/51941/

##  安装npm

```bash
choco install nodejs-lts -y
```



## 安装hexo

```bash
npm install -g hexo-cli
npm install hexo

# 部署hexo时需要的插件
npm install hexo-deployer-git --save

# 安装hexo-server，用于预览静态网站
npm install hexo-server --save
```



## 建站

```bash
# 初始化站点
mkdir blog && cd blog
hexo init
npm install

# clone代码库
git clone https://github.com/omaidb/omaidb.github.io.git

# cd 到你的githubpage目录下
cd omaidb.github.io

# 将blog目录下的文件全部拷贝到git项目下,拷贝完成后可以删除blog目录

# 将hexo代码上传
git add -A
git commit -m 'hexo init'
git push
```



## 新建一篇文章

https://hexo.io/zh-cn/docs/commands

```bash
# 新建一篇文章
hexo new [layout] <title>

# 示例
hexo new "文章标题"
```



## 生成静态文件

```bash
# 生成静态文件hexo generate
hexo g

# 持续生成静态文件
hexo g -w

# 生成并立即发布文章
hexo g -d
```



## 发表草稿

```bash
hexo publish [layout] <filename>
```



## 预览

```bash
hexo server
# 会打开http://localhost:4000/
```



## 部署

```bash
hexo deploy
```


