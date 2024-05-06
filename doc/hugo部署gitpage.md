## 安装hugo

```bash
choco install hugo hugo-extended -y
```



## 新建一个站点

参考: [https://zzo-docs.vercel.app/zzo/gettingstarted/installation/](https://zzo-docs.vercel.app/zzo/gettingstarted/installation/)

```bash
hugo new site hugo-blog
cd hugo-blog
```



## 添加主题

参考: [添加zzo主题](https://zzo-docs.vercel.app/zzo/gettingstarted/installation/)

```bash
cd myblog
git init

# 将zzd主题添加为子模块
git submodule add https://github.com/zzossig/hugo-theme-zzo.git themes/zzo
```



## 添加配置文件

我们必须制作 4 个配置文件才能使主题正常工作。查看[配置文件](https://zzo-docs.vercel.app/zzo/configuration/configfiles/)部分。

- [config.toml] - 我们可以设置 Hugo 本身相关的配置参数。
- [languages.toml] - 我们可以更改语言相关设置。
- [menus.en.toml] - 我们可以添加或删除站点菜单。
- [params.toml] - 此文件中的参数仅用于 zzo 主题。



## 添加博客菜单

通过制作`menus.en.toml`文件来创建您的博客菜单。`en`可以是任何国家代码。我将在本指南中制作一个帖子菜单。

```bash
[[main]]
  identifier = "posts"
  name = "Posts"
  url = "posts"
  weight = 1
  ...
```

## 添加内容

我要在文件`posts`夹中创建文件`root/content/en`夹。菜单的根文件夹应该有`_index.md`文件。

`/content/en/posts/_index.md`

```bash
---
title: "Post section"
date: 2019-03-26T08:47:11+01:00
description: All the list of my posts
---
```

## 添加一篇文章

`/content/en/posts/文章标题.md`

```bash
---
title: "文章标题"
date: 2019-03-26T08:47:11+01:00
description: This is my awesome post!
draft: false
---

Your markdown here.
```



## 更新网站

```bash
git submodule update --remote --merge
```



## 查看示例网站

从主题/zzo/exampleSite 的根目录：

```bash
hugo server --themesDir ../..
```

