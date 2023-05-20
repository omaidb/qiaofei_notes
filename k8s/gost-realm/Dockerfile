# 请勿使用latest标签
FROM alpine:3.17.2 as unzip
# 设置gost版本号
ARG realm_VERSION=2.4.5
# 下载GOST3并解压gost
ADD https://github.com/zhboner/realm/releases/download/v${realm_VERSION}/realm-x86_64-unknown-linux-gnu.tar.gz ./realm-x86_64-unknown-linux-gnu.tar.gz

# 删除除gost程序以外的文件
RUN tar xf realm-x86_64-unknown-linux-gnu.tar.gz

# 将本地的配置文件复制到/etc/gost
COPY realm.toml ./realm.toml

# 容器使用的端口
EXPOSE 1080/tcp
EXPOSE 1080/udp
# 运行主程序
ENTRYPOINT realm -c realm.toml

FROM keybaseprivate/glibc as copy_pkg
# 作者信息
LABEL qiaofei.li="https://blog.csdn.net/omaidb"
# USER <用户名>[:<用户组>]
# 清理多余文件
RUN rm -rf /tmp/glibc-2.27-r0.apk /tmp/glibc-bin-2.27-r0.apk
USER nobody:nobody
# 设置工作目录
WORKDIR /app
COPY  --from=unzip ./realm .
COPY realm.toml .
EXPOSE 443/tcp
EXPOSE 443/udp
EXPOSE 26000/udp
ENTRYPOINT realm -c realm.toml