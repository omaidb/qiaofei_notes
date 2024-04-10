#!/usr/bin/env bash

# 开启debug
# set -ex

# 获取公网IP地址
server_public_ip=$(curl -s ipv4.icanhazip.com)

# 为node分配IP地址
gen_node_ip() {
  ## 统计目录下的配置名数量,+2就是已创建的ip数量
  ip_sum=$(ls /etc/nebula/node/ | wc -l)
  # 新增的ip地址=已创建的ip数量+1
  ip_add_host=$((ip_sum + 1))
  # shell脚本的变量默认是全局变量
  ip_add="10.187.71.$ip_add_host"
}

# 为node签发证书
Issue_a_certificate_for_node() {
  node_name=$1
  # 判断node证书文件是否存在
  ls /etc/nebula/node/"$node_name"/"$node_name".crt &>/dev/null && echo "$node_name.crt证书文件已存在，脚本停止" && exit 1
  ls /etc/nebula/node/"$node_name"/"$node_name".key &>/dev/null && echo "$node_name.key密钥文件已存在，脚本停止" && exit 1
  mkdir -p /etc/nebula/node/"$node_name" && cd /etc/nebula/node/"$node_name" || exit
  # 复制CA文件证书到nodename配置目录下
  cp /etc/nebula/ca.crt /etc/nebula/node/"$node_name"/ca.crt
  ## -name，就是这个节点的名字，可以任意填写，也可以用域名的方式填写
  ## -ip，指定 Nebula 分配给该节点的 IP 地址，需要手动指定，且不能与已分配的 IP 地址冲突
  ## -subnets，指定当前节点的非 Nebula 路由，以便其它节点能访问当前节点的子网
  ## -group，指定该节点所在的组，方便 Nebula 进行防火墙规则配置
  ## -ca-crt 指定CA证书
  ## -ca-key 指定CA密钥
  ## -out-crt 指定输出证书路径
  ## -out-key 证书输出密钥路径
  nebula-cert sign -ca-crt /etc/nebula/ca.crt -ca-key /etc/nebula/ca.key -name "$node_name" -ip "$ip_add/24" -out-crt /etc/nebula/node/"$node_name"/"$node_name".crt -out-key /etc/nebula/node/"$node_name"/"$node_name".key
  # 会在目录下生成一个与 -name 相匹配的 lighthouse.crt 证书文件 和 lighthouse.key 密钥文件。
}

# 创建node配置文件
create_node_config() {
  cat <<EOF >/etc/nebula/node/"$node_name"/"$node_name".yml
pki:
  ca: /etc/nebula/$node_name/ca.crt
  cert: /etc/nebula/$node_name/$node_name.crt
  key: /etc/nebula/$node_name/$node_name.key

# 静态主机映射
static_host_map:
  "10.187.71.1": ["$server_public_ip:4242"]

lighthouse:
  # 是否灯塔节点
  am_lighthouse: false
  interval: 60
  hosts:
    # node配置上要指定灯塔的nebula内网地址
    - 10.187.71.1

listen:
  # host: "[::]"
  host: "0.0.0.0"
  # 非灯塔节点端口设为动态端口
  port: 0

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
}

# 为node分配IP
gen_node_ip
# 为node签发证书
Issue_a_certificate_for_node "$@"
# 为node创建配置文件
create_node_config
