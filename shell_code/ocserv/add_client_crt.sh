#!/usr/bin/env bash

# 开启debug
set -ex

# 证书签发脚本
# 参考：https://mp.weixin.qq.com/s/Y5dcAv7ChE19QDd_662RQQ
# 参考：https://wwww.lvmoo.com/1097.love/
# 参考 https://www.jianshu.com/p/ab9523a6c0f4

## CA相关文件目录
### 证书模板存放目录
TEMPLATE_DIR=/etc/ocserv/template
### 根证书存放路径
ROOT_SSL_DIR=/etc/ocserv/root_ssl
### 服务端证书存放路径
SERVER_SSL_DIR=/etc/ocserv/server_ssl
### 用户证书存放路径
USER_SSL_DIR=/etc/ocserv/user_ssl
### 用户公网证书存放路径
USER_PUBLIC_SSL_DIR=/etc/letsencrypt/live/
### 吊销的证书存放路径
REVOKED_SSL_DIR=/etc/ocserv/revoked_ssl
## 域名
domain_name="roadstar.vip"
domain_reg_email="omaidb@gmail.com"
## 获取公网IP地址
IP_ADD=$(curl -s ipv4.icanhazip.com | xargs echo -n)

# 环境检查
check_ocserv_env() {
    ## 先判断有没有python3
    which python3 &>/dev/null || (yum install -y python3 && which python3 || exit 1)
    ## 判断certtool有无安装
    which certtool &>/dev/null || (yum install -y gnutls* gnutls-utils gnutls-devel libev-devel && which certtool || exit 1)
    # 创建libgnutls.so的软链接
    ls /usr/include/gnutls/x509.h &>/dev/null || ln -s /usr/lib64/libgnutls.so.28.43.3 /lib/libgnutls.so
}
# 检查必须目录
check_must_dir() {
    # 建立相关证书配置文件夹
    mkdir -p "$TEMPLATE_DIR" || exit 1
    # CA文件默认存放的目录
    # mkdir -p /etc/pki/CA/{certs,newcerts,private,crl}
    # 创建根证书文件存放目录
    mkdir -p "$ROOT_SSL_DIR"
    # 创建服务器证书存放目录
    mkdir -p "$SERVER_SSL_DIR"
    # 创建用户证书存放目录
    mkdir -p "$USER_SSL_DIR"
    # 创建吊销证书存放目录
    mkdir -p "$REVOKED_SSL_DIR"
}

# 建立ca模板
create_root_ca_template() {
    ls "$TEMPLATE_DIR"/ca.tmpl &>/dev/null && echo "CA根证书模板已经存在" && exit 1
    cat <<EOF >"$TEMPLATE_DIR"/ca.tmpl
cn = "NFSC CA"
organization = "NFSC"
serial = 2
expiration_days = 3650
ca
signing_key  
cert_signing_key  
crl_signing_key  
EOF
}

# 创建根CA
create_root_ca() {
    cd "$ROOT_SSL_DIR" || exit
    # 生成根CA私钥
    ls "$ROOT_SSL_DIR"/ca-key.pem &>/dev/null && echo "CA根证书文件已经存在" && exit 1
    certtool --generate-privkey --outfile "$ROOT_SSL_DIR"/ca-key.pem

    # 生成根CA密钥及CA根证书文件
    certtool --generate-self-signed \
        --hash SHA256 \
        --load-privkey "$ROOT_SSL_DIR"/ca-key.pem \
        --template "$TEMPLATE_DIR"/ca.tmpl \
        --outfile "$ROOT_SSL_DIR"/ca-cert.pem
}

# 创建服务器模版
create_server_template() {
    ls "$TEMPLATE_DIR"/ocserv_server.tmpl &>/dev/null && echo "Server服务端证书模板已经存在" && exit 1
    cat <<EOF >"$TEMPLATE_DIR"/ocserv_server.tmpl
cn = "NFSC Openconnect Server"
organization = "NFSC"
serial = 2
expiration_days = 3527
signing_key
encryption_key #仅当生成的密钥是 RSA 密钥时指定
tls_www_server
dns_name = "$domain_name"
# dns_name = "vpn1.example.com"
ip_address = "$IP_ADD"
EOF
}
# 获取公网证书
create_public_server_cert() {
    ls "$USER_PUBLIC_SSL_DIR"/"$domain_name"/fullchain.pem "$USER_PUBLIC_SSL_DIR"/"$domain_name"/privkey.pem &>/dev/null && echo "公网Server密钥和证书文件已经存在" && exit 1
    certbot certonly --standalone --agree-tos --email $domain_reg_email -d $domain_name
}

# 创建Server密钥和证书
create_server_key_and_cert() {
    cd "$SERVER_SSL_DIR" || exit
    ls "$SERVER_SSL_DIR"/ocserv_server-key.pem &>/dev/null && echo "Server密钥和证书文件已经存在" && exit 1
    ## 生成Server私钥
    certtool --generate-privkey --outfile "$SERVER_SSL_DIR"/ocserv_server-key.pem

    ## 生成Server证书
    certtool --generate-certificate \
        --load-privkey "$SERVER_SSL_DIR"/ocserv_server-key.pem \
        --load-ca-certificate "$ROOT_SSL_DIR"/ca-cert.pem \
        --load-ca-privkey "$ROOT_SSL_DIR"/ca-key.pem \
        --template "$TEMPLATE_DIR"/ocserv_server.tmpl \
        --outfile "$SERVER_SSL_DIR"/ocserv_server-cert.pem
    # 锁定服务端密钥和证书文件
    chattr +i "$SERVER_SSL_DIR"/ocserv_server-key.pem "$SERVER_SSL_DIR"/ocserv_server-cert.pem
}

# 生成DH(Diffie-Hellman)密钥
## Diffie-Hellman文件，也就是秘钥交换时的DH算法，确保密钥可以穿越不安全网络。
create_dh_ca() {
    # DH密钥的作用是：确保共享密钥KEY安全穿越不安全网络
    ls "$SERVER_SSL_DIR"/dh.pem &>/dev/null && echo "dh.pem证书文件已经存在" && exit 1
    certtool --generate-dh-params --outfile "$SERVER_SSL_DIR"/dh.pem
}

# 检查必须模板和证书文件
check_must_template_and_cret() {
    # 下面这些文件都必须存在
    # 检查CA根证书模板
    ls "$TEMPLATE_DIR"/ca.tmpl &>/dev/null || (echo "Server密钥和证书文件不存在" && create_root_ca_template)
    # 检查CA根证书文件
    ls "$ROOT_SSL_DIR"/ca-key.pem &>/dev/null || (echo "Server密钥和证书文件不存在" && create_root_ca)
    # 检查SERVER端证书模板
    ls "$TEMPLATE_DIR"/ocserv_server.tmpl &>/dev/null || (echo "Server密钥和证书文件不存在" && create_server_template)
    # 检查SERVER端证书文件
    ls "$SERVER_SSL_DIR"/ocserv_server-key.pem &>/dev/null || (echo "Server密钥和证书文件不存在" && create_server_key_and_cert)
    # 检查DH证书文件
    ls "$SERVER_SSL_DIR"/dh.pem &>/dev/null || (echo "Server密钥和证书文件不存在" && create_dh_ca)
    # 检查吊证证书模板和吊销证书文件
    ls "$TEMPLATE_DIR"/crl.tmpl &>/dev/null || (echo "吊销证书模板文件不存在" && create_revoked_template)
}

# 创建user(Client)证书模板
create_client_template() {
    echo "请输输入要签发证书的用户名:"
    read -r OCSERV_USER_NAME
    ls "$TEMPLATE_DIR"/"$OCSERV_USER_NAME".tmpl &>/dev/null && echo "Client证书模板已经存在" && exit 1
    cat >"$TEMPLATE_DIR"/"$OCSERV_USER_NAME".tmpl <<EOF
cn = "$OCSERV_USER_NAME"
unit = "$OCSERV_USER_NAME unit"
expiration_days = 3527
signing_key
encryption_key # 仅当生成的密钥是RSA时
tls_www_client
EOF
}

# 创建Client密钥和证书
create_client_key_and_cert() {
    cd "$USER_SSL_DIR" || exit
    ls "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-key.pem &>/dev/null && echo "Client证书文件已经存在" && exit 1
    # 生成Client私钥
    certtool --generate-privkey --outfile "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-key.pem

    # 生成Client证书
    certtool --generate-certificate \
        --load-privkey "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-key.pem \
        --load-ca-certificate "$ROOT_SSL_DIR"/ca-cert.pem \
        --load-ca-privkey "$ROOT_SSL_DIR"/ca-key.pem \
        --template "$TEMPLATE_DIR"/"$OCSERV_USER_NAME".tmpl \
        --outfile "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-cert.pem
}
# 创建公网Client密钥和证书
create_public_client_key_and_cert() {
    cd "$USER_PUBLIC_SSL_DIR" || exit
    ls "$USER_PUBLIC_SSL_DIR"/"$domain_name"/"$OCSERV_USER_NAME"-key.pem &>/dev/null && echo "Client证书文件已经存在" && exit 1
    # 生成Client私钥
    certtool --generate-privkey --outfile "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-key.pem

    # 生成Client证书
    certtool --generate-certificate \
        --load-privkey "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-key.pem \
        --load-ca-certificate "$ROOT_SSL_DIR"/ca-cert.pem \
        --load-ca-privkey "$ROOT_SSL_DIR"/ca-key.pem \
        --template "$TEMPLATE_DIR"/"$OCSERV_USER_NAME".tmpl \
        --outfile "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-cert.pem
}

# 补全证书链
# cat "$ROOT_SSL_DIR"/ca-cert.pem >>"$USER_SSL_DIR"/"$OCSERV_USER_NAME"-cert.pem

# 为client生成.p12证书文件
create_client_p12() {
    ls "$USER_SSL_DIR"/"$OCSERV_USER_NAME".p12 &>/dev/null && echo "Client的p12证书文件已经存在" && exit 1
    ## --empty-password 强制使用空密码
    certtool --to-p12 \
        --empty-password \
        --p12-name="$OCSERV_USER_NAME" \
        --load-privkey "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-key.pem \
        --pkcs-cipher 3des-pkcs12 \
        --load-certificate "$USER_SSL_DIR"/"$OCSERV_USER_NAME"-cert.pem \
        --outfile "$USER_SSL_DIR"/"$OCSERV_USER_NAME".p12 --outder
}

# 查看用户状态
show_user_status() {
    occtl show users
}
# 创建吊销证书的模板
create_revoked_template() {
    cd "$TEMPLATE_DIR" || exit
    ls "$TEMPLATE_DIR"/crl.tmpl &>/dev/null && echo "吊销证书模板文件已经存在" && exit 1
    # 创建吊销证书模板文件
    cat <<EOF >"$TEMPLATE_DIR"/crl.tmpl
crl_next_update = 365
crl_number = 1
EOF
}

# 吊销client证书
delete_client_ca() {
    # 吊销证书前先看下用户的状态
    show_user_status
    cd "$USER_SSL_DIR" || exit
    echo "请输入要吊销的用户:"
    local ocserv_user
    read -r ocserv_user
    # 将当前有效的用户密钥追加到撤销证书中间文件中
    cat "$USER_SSL_DIR"/"${ocserv_user}"-cert.pem >>"$REVOKED_SSL_DIR"/revoked.pem

    # 撤销指定用户的证书
    certtool --generate-crl \
        --load-ca-privkey "$ROOT_SSL_DIR"/ca-key.pem \
        --load-ca-certificate "$ROOT_SSL_DIR"/ca-cert.pem \
        --load-certificate "$REVOKED_SSL_DIR"/revoked.pem \
        --template "$TEMPLATE_DIR"/crl.tmpl \
        --outfile "$REVOKED_SSL_DIR"/crl.pem
    # 取消ocserv.conf中的crl注释
    set_config_crl
}

# 取消ocserv.conf中的crl注释
set_config_crl() {
    # 先取出配置文件中的crl的字符串
    crl_str_var=$(grep crl /etc/ocserv/ocserv.conf)
    # 判断配置文件中是否注释了crl
    if [[ "$crl_str_var" =~ ^#.* ]]; then
        # 取消配置文件中的crl注释
        sed -i '/^#.*crl/s/^#//g' /etc/ocserv/ocserv.conf
        # 重启ocserv服务
        systemctl restart ocserv
    fi

}

#开始菜单
function start_menu() {
    # 先进行环境检查
    check_ocserv_env
    # 检查必须目录
    check_must_dir
    # 检查CA和服务端证书是否存在
    check_must_template_and_cret
    clear
    echo "========================="
    echo " 介绍：适用于CentOS7"
    echo " 作者：Miles"
    echo " 网站：https://blog.csdn.net/omaidb"
    echo "========================="
    echo "注意：本脚本只支持Centos7"
    echo "1. 为指定ocserv用户签发证书"
    echo "2. 吊销指定ocserv用户证书"
    echo "0. 退出脚本"
    echo "请输入数字:"
    read -r num
    case "$num" in
    1)
        echo "为指定ocserv用户签发证书"
        # 查看用户状态
        show_user_status
        # 建立user(Client)证书模板
        create_client_template
        # 创建Client密钥和证书
        create_client_key_and_cert
        # 为client生成.p12证书文件
        create_client_p12
        ;;
    2)
        echo "吊销指定ocserv用户证书"
        # 吊销client证书
        delete_client_ca
        ;;
    0)
        exit 1
        ;;
    *)
        clear
        echo "请输入正确数字"
        sleep 5s
        start_menu
        ;;
    esac
}

# main方法，显示菜单
start_menu
