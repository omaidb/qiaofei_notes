#!/usr/bin/env bash

# 应用程序列表
## 将所有要启动的程序写入到一个列表中
node_list=(
    # 数据结构如下：
    ## "${ipfs_node_ip} : ${Peer_ID}"
    # ipfs1
    "192.168.0.1:QmV7Thb3mjuWa1xDK5UrgtG7SSYFt4PSyvo6CjcnA5gZAg"
    # ipfs2
    "192.168.0.2:QmV7Thb3mjuWa1xDK5UrgtG7SSYFt4PSyvo6CjcnA5gZAg"
    # ipfs3
    "192.168.0.3:QmV7Thb3mjuWa1xDK5UrgtG7SSYFt4PSyvo6CjcnA5gZAg"
    # ipfs4
    "192.168.0.4:QmV7Thb3mjuWa1xDK5UrgtG7SSYFt4PSyvo6CjcnA5gZAg"
)

# 添加集群节点到节点的bootstrap列表中
add_nodeip_to_bootstrap_list() {
    # IPFS的节点IP地址
    local ipfs_node_ip="$1"
    # Peer ID(对等节点标识符)
    local Peer_ID="$2"
    # ipfs bootstrap add /ip4/${ipfs节点的IP地址}/tcp/4001/ipfs/${Peer ID(对等节点标识符)}
    ipfs bootstrap add /ip4/"$ipfs_node_ip"/tcp/4001/ipfs/"$Peer_ID" 2>&1 &
}

# 遍历应用程序列表并启动应用程序
for ipfs_node_info in "${node_list[@]}"; do
    # 从列表中提取出ip和Peer_ID
    IFS=':' read -r ipfs_node_ip Peer_ID <<<"${ipfs_node_info}"
    # echo "${ipfs_node_ip}" "${Peer_ID}"
    # 添加集群节点到节点的bootstrap列表中
    add_nodeip_to_bootstrap_list "${ipfs_node_ip}" "${Peer_ID}"
done
