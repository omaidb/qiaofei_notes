#!/usr/bin/env bash

## --disable-obscure  禁用混淆，以节省一些带宽和 CPU，更不易被检测到多倍发包。
## --disable-checksum 禁用校验和，以节省一些带宽和 CPU。
# 服务端配置
/usr/local/bin/speederv2_amd64 -s -l 0.0.0.0:122 -r 10.0.0.189:11194 -k 05 -f 2:7 --timeout 0 --mode 0 -q1 -i 10 --disable-obscure --disable-checksum

# 客户端配置
## --timeout 0 降低延时，流量增加
udpspeeder -c -l 0.0.0.0:3389 -r 152.70.110.134:122 -k 05 -f 2:7 --timeout 0 --mode 0 -q1 -i 10 --disable-obscure --disable-checksum