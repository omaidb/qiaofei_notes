#!/usr/bin/env bash

# 开启debug
# set -ex

# 灯塔节点创建CA
create_CA() {
  # 定义变量
  CA_name="NFSC"
  # 判断CA文件是否存在
  ls /etc/nebula/ca.crt &>/dev/null && echo "ca.crt证书文件已存在，脚本停止" && exit 1
  ls /etc/nebula/ca.key &>/dev/null && echo "ca.key密钥文件已存在，脚本停止" && exit 1
  cd /etc/nebula || exit
  ## -groups：该CA认证书签发的子认证书可以使用哪些组，这些组可以方便地配置防火墙策略。
  ## -ips：该CA认证书适用的IP地址段。
  ## -name：该CA的名称。
	## -duration  876000h0m0s是证书有效期（100年），设长一点防止过期。
  nebula-cert ca -name $CA_name -duration 876000h0m0s
  # 会在当前目录下生成 ca.key（私钥）和 ca.crt（证书）两个文件
  # 锁定CA文件
  chattr +i /etc/nebula/ca.crt /etc/nebula/ca.key
}

# 为灯塔签发证书
Issuing_certificates_for_lighthouses() {
  node_name="lighthouse"
  # 判断灯塔node证书文件是否存在
  ls /etc/nebula/node/$node_name/$node_name.crt &>/dev/null && echo "$node_name.crt证书文件已存在，脚本停止" && exit 1
  ls /etc/nebula/node/$node_name/$node_name.key &>/dev/null && echo "$node_name.key密钥文件已存在，脚本停止" && exit 1
  mkdir -p /etc/nebula/node/$node_name && cd /etc/nebula/node/$node_name || exit
  ## -name，就是这个节点的名字，可以任意填写，也可以用域名的方式填写
  ## -ip，指定 Nebula 分配给该节点的 IP 地址，需要手动指定，且不能与已分配的 IP 地址冲突
  ## -subnets，指定当前节点的非 Nebula 路由，以便其它节点能访问当前节点的子网
  ## -group，指定该节点所在的组，方便 Nebula 进行防火墙规则配置
  ## -ca-crt 指定CA证书
  ## -ca-key 指定CA密钥
  ## -out-crt 指定输出证书路径
  ## -out-key 证书输出密钥路径
  nebula-cert sign -ca-crt /etc/nebula/ca.crt -ca-key /etc/nebula/ca.key -name $node_name -ip "10.187.71.1/24" -out-crt /etc/nebula/node/$node_name/$node_name.crt -out-key /etc/nebula/node/$node_name/$node_name.key
  # 会在目录下生成一个与 -name 相匹配的 lighthouse.crt 证书文件 和 lighthouse.key 密钥文件。
}

# 创建灯塔配置文件
create_lh_config() {
  cat <<EOF >/etc/nebula/node/$node_name/$node_name.yml
pki:
  ca: /etc/nebula/ca.crt
  cert: /etc/nebula/node/$node_name/$node_name.crt
  key: /etc/nebula/node/$node_name/$node_name.key

lighthouse:
  # 是否灯塔节点
  am_lighthouse: true
  interval: 60

listen:
  # host: "[::]"
  host: "0.0.0.0"
  # 灯塔节点固定端口
  port: 4242

# 打洞配置
punchy:
  # 是否打洞
  punch: true
  # 是否反向打洞
  punch_back: true

# 加密方式-默认aes
## chachapoly比较省资源
cipher: chachapoly

# 本地网段
# 能够快速地找到用以建立连接的最快的路径，这适用于设备处于同一个局域网内。
# local_range: 10.0.0.0/8

# tun隧道配置
tun:
  disabled: false
  dev: nebula1
  drop_local_broadcast: false
  drop_multicast: false
  tx_queue: 500
  mtu: 1300

logging:
  level: info
  format: text

# 防火墙配置
firewall:
  # 出站配置
  outbound:
    - port: any
      proto: any
      host: any
  # 入站配置
  inbound:
    - port: any
      proto: any
      host: any
EOF
    # 为主程序创建配置文件软连接
    ln -s /etc/nebula/node/$node_name/$node_name.yml /etc/nebula/config.yml
}

# 创建CA
create_CA
# 为灯塔node签发证书
Issuing_certificates_for_lighthouses
# 为灯塔node创建配置文件
create_lh_config
# 重启nebula服务
systemctl restart nebula
