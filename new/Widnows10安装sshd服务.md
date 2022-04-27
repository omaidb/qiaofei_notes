## Windwos10安装sshd服务
安装ssh套件和ssh-copy-id

```bash
# 安装openssh和ssh-copy-id
choco install openssh ssh-copy-id -y
```


## 启动sshd服务

```bash
# 进入sshd目录
cd "C:\Program Files\OpenSSH-Win64"

# 执行install-sshd.ps1脚本
.\install-sshd.ps1

# 重启sshd服务
Restart-Service sshd

# 重启ssh-agent服务
Restart-Service ssh-agent

# 查看ssh服务和ssh-agent服务是否运行
Get-Service ssh
Get-Service ssh-agent

# 查看22端口是否处于监听状态
netstat -ano|grep 22

# telnet测试本地22端口是开放
telnet 127.0.0.1 22
```

## 配置Win10的sshd服务--免密登录
ssh的配置文件在`C:\ProgramData\ssh\sshd_config`

`vim C:\ProgramData\ssh\sshd_config`
```bash
# 非常重要
PubkeyAuthentication yes
AuthorizedKeysFile  .ssh/authorized_keys
PasswordAuthentication no  #(需要将默认的yes改为no,很重要)
```

注释文件`最后`几行
```bash
 #Match Group administrators
       #AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

修改完配置`一定要重启`sshd服务
```bash
Restart-Service sshd
```

### 设置ssh登录后默认的shell
设置shell为`powershell`
```bash
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

设置shell为`pwsh7`
```bash
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
```



## 配置密钥免密登录

```bash
# 生成密钥对
ssh-keygen

# 将私钥加载到ssh-agent
ssh-add ~\.ssh\id_rsa
```

### scp上传公钥到ssh服务器

```bash
# 上传私钥到ssh服务器
scp C:\Users\username\.ssh\id_rsa.pub user1@domain1@contoso.com:C:\Users\username\.ssh\authorized_keys
```

### ssh-copy-id上传公钥到ssh服务器
`ssh-copy-id`没成功,报错`umask`问题
```bash
ssh-copy-id username@hostip
```

## ssh登录Windows-sshd服务器
```bash
ssh username@hsotip
```
