# 请勿使用latest标签
FROM alpine:latest as unzip
# 设置gost版本号
ARG realm_VERSION=2.4.6
# 下载GOST3并解压gost
ADD https://github.com/zhboner/realm/releases/download/v${realm_VERSION}/realm-x86_64-unknown-linux-musl.tar.gz ./realm-x86_64-unknown-linux-musl.tar.gz

# 删除除gost程序以外的文件
RUN tar xf realm-x86_64-unknown-linux-musl.tar.gz

# 将本地的配置文件复制到/etc/gost
COPY realm.toml ./realm.toml

FROM alpine:latest as copy_pkg
# 作者信息
LABEL qiaofei.li="https://blog.csdn.net/omaidb"
# USER <用户名>[:<用户组>
USER nobody:nobody
# 设置工作目录
WORKDIR /app
COPY  --from=unzip ./realm .
COPY realm.toml .
# 容器使用的端口
EXPOSE 1080/tcp
EXPOSE 1080/udp
# 启动主程序
ENTRYPOINT /app/realm -c realm.toml