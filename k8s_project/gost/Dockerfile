# 阶段1,解压gost压缩包
## 请勿使用latest标签
FROM alpine:latest as unzip
# 设置gost版本号
ARG GOST_VERSION=3.0.0-rc8
# 下载GOST3压缩包
ADD https://github.com/go-gost/gost/releases/download/v"${GOST_VERSION}"/gost_"${GOST_VERSION}"_linux_amd64.tar.gz .
# 解压gost压缩包
RUN tar xvf gost_${GOST_VERSION}_linux_amd64.tar.gz

# 阶段2,复制gost可执行程序
FROM alpine:latest as copy_gost_bin
# 作者信息
LABEL qiaofei.li="https://blog.csdn.net/omaidb"
# 设置工作目录
WORKDIR /app
# 将unzip阶段的的gost可执行程序复制到当前目录
COPY --from=unzip gost .
# 将本地的配置文件复制到当前目录
COPY gost.yaml .
# USER <用户名>[:<用户组>]
# USER nobody:nobody
# 容器使用的端口
EXPOSE 1080/tcp
EXPOSE 1080/udp
# 运行主程序--指定绝对路径
ENTRYPOINT /app/gost -C gost.yaml
