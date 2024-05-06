---
title: macOS显示隐藏文件
date: 2022-02-22 23:18:06
tags: macOS
---



## 苹果Mac操作系统下怎么显示隐藏文件



<br/>



## 1\. Terminal

最简单的是通过在Mac终端输入命令。  

显示隐藏文件（注意空格和大小写）：

```bash
defaults write com.apple.finder AppleShowAllFiles -bool true
```

或

```bash
defaults write com.apple.finder AppleShowAllFiles YES
```

不显示隐藏文件：

```bash
defaults write com.apple.finder AppleShowAllFiles -bool false 
```

或

```bash
defaults write com.apple.finder AppleShowAllFiles NO
```

输入完成后，单击Enter键，然后直接退出终端，重新启动Finder即可。  
重启Finder：首先强制退出Finder，再重新启动Finder即可。



<br/>



## 2\. 快捷键

1.  在这里隐藏文件所在的目录按键盘上面的`shift+cmmand+.` ，接着看到隐藏文件夹内凡是前面带有小点的隐藏文件，或者是显示淡蓝色的文件都是隐藏文件。通过这个方式就可以查看隐藏的目录。
2.  要恢复隐藏文件的话再次按`shift+cmmand+.` ，即可恢复文件的隐藏状态，如图二隐藏的文件已经不可见。