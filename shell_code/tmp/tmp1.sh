#!/usr/bin/env bash
# Author: 自然自在
# Email: omaidb@gmail.com
# Description: 使用javaagent 启动并使用pinpoint-agent监控蜗牛影院系统
# Description: 原创代码，使用MIT协议开源，使用全部或部分代码，必须保留原作者信息及声明
# Description: IT培训机构不遵守MIT协议，不保留作者信息，！！！律师函警告！！！
# web: https://blog.csdn.net/omaidb
# Version:2.0
# CreateTime:2023-09-13 16:34:41


WARING_DIY() {
    echo "
作者: 自然自在
Email: omaidb@gmail.com
脚本功能描述: 使用javaagent 启动并使用pinpoint-agent监控蜗牛影院系统
!!风险警告⚠️: 该代码，使用MIT协议开源，使用全部或部分代码，必须保留原作者信息及声明
!!风险警告⚠️: IT培训机构不遵守MIT协议，不保留作者信息，！！！律师函警告！！！
web: https://blog.csdn.net/omaidb
"
}
# 声明Pinpoint代理程序的jar包路径
JAVAAGENT_PATH="/opt/pinpoint/pinpoint-agent-2.1.0/pinpoint-bootstrap.jar"

# 应用程序列表
## 将所有要启动的程序写入到一个列表中
APPS=(
    # 数据结构如下：
    ## "${jar_file} : ${agent_id} : ${同项目_app_name 相同}"
    # eureka-server1
    "eureka-server1-0.0.1-SNAPSHOT.jar:eureka1:woniuticket"
    # eureka-server2
    "eureka-server2-0.0.1-SNAPSHOT.jar:eureka2:woniuticket"
    # cinema-stage
    "cinema-stage-0.0.1-SNAPSHOT.jar:cinema:woniuticket"
    # jobs-0.0.1-SNAPSHOT
    "jobs-0.0.1-SNAPSHOT.jar:jobs:woniuticket"
    # comment-0.0.1-SNAPSHOT
    "comment-0.0.1-SNAPSHOT.jar:comment:woniuticket"
    # movie-stage
    "movie-stage-0.0.1-SNAPSHOT.jar:movie:woniuticket"
    # orders-stage
    "orders-stage-0.0.1-SNAPSHOT.jar:orders:woniuticket"
    # gateway
    "gateway-0.0.1-SNAPSHOT.jar:gateway:woniuticket"
    # user
    "user-0.0.1-SNAPSHOT.jar:user:woniuticket"
    # general
    "general-0.0.1-SNAPSHOT.jar:general:woniuticket"
    # web
    "web-0.0.1-SNAPSHOT.jar:web:woniuticket"
)

# 使用javaagent启动应用程序函数
javaagent_start_application() {
    # jar包路径
    local jar_file="$1"
    # -Dpinpoint.agentId
    local agent_id="$2"
    # -Dpinpoint.applicationName
    local app_name="$3"
    # app日志路径
    local log_file="${agent_id}.log"
    # 使用javaagent启动jar包，并输出日志
    ## 要传入-Dpinpoint.agentId 和 -Dpinpoint.applicationName
    java -javaagent:"${JAVAAGENT_PATH}" -Dpinpoint.agentId="${agent_id}" -Dpinpoint.applicationName="${app_name}" \
        -jar "/opt/qianyao/xm/${jar_file}" >"/var/log/qianyao/${log_file}" 2>&1 &
}

# 遍历应用程序列表并启动应用程序
for app in "${APPS[@]}"; do
    IFS=':' read -r jar_file agent_id app_name <<<"${app}"
    # echo "${jar_file}" "${agent_id}" "${app_name}"
    ## echo示例：eureka-server1-0.0.1-SNAPSHOT.jar eureka1 woniuticket
    javaagent_start_application "${jar_file}" "${agent_id}" "${app_name}"
    # 警告
    WARING_DIY
done
