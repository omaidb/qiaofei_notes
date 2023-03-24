FROM keybaseprivate/glibc
ARG v=2.4.5
WORKDIR /app
# 删除多余的apk包
ADD https://github.com/zhboner/realm/releases/download/v$v/realm-x86_64-unknown-linux-gnu.tar.gz realm-x86_64-unknown-linux-gnu.tar.gz
RUN tar zxvf realm-x86_64-unknown-linux-gnu.tar.gz && rm -rf realm-x86_64-unknown-linux-gnu.tar.gz /tmp/glibc-2.27-r0.apk /tmp/glibc-bin-2.27-r0.apk
COPY realm.toml realm.toml
# 查看是否安装好
ENTRYPOINT ./realm -c ./realm.toml