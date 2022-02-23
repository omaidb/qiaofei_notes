---
title: Centos8安装trojan
date: 2022-02-22 22:18:06
tags:
---

## yum安装前置代理
前置代理trojan依赖`epel`源
```bash
yum install trojan

# 配置文件目录
/etc/trojan/config.json
```

<br/>

### 编辑配置文件
如果提示: `SSL handshake failed`

您需要将配置文件中的 "verify":true,"verify_hostname":true, 修改为 `false` 

```json
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "pac.ibm.com",
    "remote_port": 443,
    "password": [
        "ibm123"
    ],
    "log_level": 1,
    "ssl": {
        "verify": false,
        "verify_hostname": false,
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
```

<br/>

##  ansible安装trojan剧本

```yaml
---
- hosts: all
  tasks:
    - name: install trojan telnet proxychains-ng
      yum:
        name: [trojan,telnet,proxychains-ng]
        state: latest

    - name: 拷贝trojan配置文件
      template:
        src: /root/ansible/trojan.json.j2
        dest: /etc/trojan/config.json
      notify: restat trojan

    - name: 配置proxychains.conf为127.0.0.1 1080
      lineinfile:
        path: /etc/proxychains.conf
        regexp: 'socks4 	127.0.0.1 9050'
        line: 'socks5 127.0.0.1 1080'

    - name: 启动并开机自启trojan务
      service:
        name: trojan
        enabled: yes
        state: started

  handlers:
    - name: restat trojan
      service:
        name: trojan
        state: restarted
```



<br/>



## 源码安装前置代理

项目地址: [https://github.com/trojan-gfw/trojan/releases](https://github.com/trojan-gfw/trojan/releases)
​
<br/>

### 下载安装trojan
```bash
# 下载traojan
wget https://ghproxy.com/https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz

# 解压
tar xvf trojan-1.16.0-linux-amd64.tar.xz -C /opt/
```

<br/>

### 创建配置文件
```bash
cd /opt/trojan && touch config.json

# 从从官网获取config配置,粘贴到config.json中
```

<br/>

### 配置开机自启动
参考: [https://blog.csdn.net/omaidb/article/details/120519191](https://blog.csdn.net/omaidb/article/details/120519191)
​
<br/>

#### 安装supervisor
```bash
#启用epel库
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#安装
yum install -y supervisor

#开机自启
sudo systemctl enable --now supervisord
```

<br/>

#### 配置trojan开机自启
在`/etc/supervisord.d`中创建`trojan.ini`文件.
```bash
#程序的名称
[program:trojan] 
#执行的命令
command = /opt/trojan/trojan -c /opt/trojan/trojan/config.json
#命令执行的目录
directory = /opt/trojan/

#执行进程的用户
user = root 
#停止方法
stopsignal = INT
#是否自动启动
autostart = true 
#是否自动重启
autorestart = true 
#自动重启间隔
startsecs = 1 
#错误输出路径
stderr_logfile = /var/log/trojan.err.log 
#日志输出路径
stdout_logfile = /var/log/trojan.out.log
```

<br/>

#### 启动trojan
```bash
# 热重启，不会重启其他子进程(reread是重读的意思,比reload高级)
supervisorctl reread
# 使用update命令,也会启动脚本
supervisorctl update

#查看所有任务状态
supervisorctl status 
```

<br/>

### 测试trojan
```bash
telnet 127.0.0.1 1080
```

<br/>



## ansible源码安装trojan剧本
```yaml
---
- hosts: all
  tasks:
    - name: wget tojan
      get_url:
        url: https://ghproxy.com/https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
        dest: /root/
    - name: mkdir -p /opt
      file:
        path: /opt
        state: directory

    - name: 解压文件
      shell: tar xvf trojan-1.16.0-linux-amd64.tar.xz -C /opt/
    - name: 创建json配置文件
      file:
        path: /opt/trojan/config.json
        state: file
        
    - name: 添加json配置
      copy:
        content: '{{ 从官网复制配置内容 }}'
        dest: /opt/trojan/config.json

    - name: 安装supervisor
      yum:
        name: supervisor
    - name: 启动并开机自启supervisor服务
      service:
        name: supervisord
        enabled: yes
        state: started
    - name: 配置trojan开机自启
      copy:
        src: /root/ansible/trojan.ini
        dest: /etc/supervisord.d/
    - name: 启动trojan
      shell: 'supervisorctl reread && supervisorctl update'
```
<br/>

## 设置临时全局代理
[https://zhuanlan.zhihu.com/p/46973701](https://zhuanlan.zhihu.com/p/46973701)
```bash
export ALL_PROXY=socks5://127.0.0.1:1080
# 如果想开机自启,写入到`.bashrc`中
```