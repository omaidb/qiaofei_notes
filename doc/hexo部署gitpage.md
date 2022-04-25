---
title: hexo部署gitpage
date: 2022-03-10 22:45:51
tags: hexo
---

参考: https://hexo.io/zh-cn/docs/setup

https://qlzhu.github.io/blog/51941/

##  安装npm

```bash
choco install nodejs-lts -y
```



## 安装hexo

```bash
npm install hexo-cli -g
npm install hexo

# 安装hexo部署插件
npm install hexo-deployer-git --save

# 安装hexo-server，用于预览静态网站
npm install hexo-server --save

# 安装本地搜索插件
npm install hexo-generator-searchdb --save

# 安装文章字数统计及阅读时常功能
npm install hexo-wordcount --save

# 安装图片显示插件(实测没用)
npm install hexo-asset-img --save
```



## 建站

```bash
# clone代码库
git clone https://github.com/omaidb/omaidb.github.io.git

# cd 到你的githubpage目录下
cd omaidb.github.io

# 初始化站点
mkdir blog && cd blog
hexo init
npm install

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

# 编辑这个文章
source\_posts\hexo部署gitpage.md
```



## 创建一个about me页面

```bash
hexo new page --path about/me "About me"
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

# 示例
hexo publish "文章标题"
```



## 预览

```bash
hexo s
# 会打开http://localhost:4000/
```



## 常见问题:部署后,网页仍未更新

```bash
# 解决办法清除缓存和已生成的静态文件
hexo clean && hexo g -d
```





## 其他美化

参考: [hexo-next主题配置](https://blog.csdn.net/as480133937/article/details/100138838)



## hexo不显示图片

找好久,有让装插件的,有改Typora图片路径的,但是都不奏效哈.头疼,还没解决.