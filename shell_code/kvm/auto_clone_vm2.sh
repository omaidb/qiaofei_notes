#!/usr/bin/env bash

# 开启debug
set -ex

# 以时间格式生成VM_NAME
function generate_vm_name() {
  # 定义虚拟机名称的前缀
  local VM_NAME_PREFIX="vm"
  # 获取当前时间,精确到纳秒
  NEWVM="${VM_NAME_PREFIX}$(date +%Y%m%d%H%M%S%N)"
  # 返回生成的随机虚拟机名称
  echo "${NEWVM}"
}

# 定义函数，用于检查虚拟机磁盘镜像是否已经存在
function check_vm_image() {
  # 检查新虚拟机的磁盘镜像是否已经存在，如果存在则输出错误消息并退出
  if [ -e "${IMG_DIR}/${NEWVM}.img" ]; then
    echo "File exists."
    exit 68
  fi
}

# 定义函数，用于创建新虚拟机的磁盘镜像
function create_vm_image() {
  # 创建新的虚拟机磁盘镜像，并提示创建结果
  echo -en "创建虚拟机磁盘映像......\t"
  # -f qcow2：指定新磁盘镜像的格式为 qcow2。
  # -b "${IMG_DIR}/${BASEVM}.img"：指定新磁盘镜像基于的现有磁盘镜像
  # ${IMG_DIR}/${NEWVM}.img 是新磁盘镜像的路径和文件名。
  # &> /dev/null：将命令的标准输出和标准错误输出都重定向到 /dev/null，即丢弃输出。
  qemu-img create -f qcow2 -b "${IMG_DIR}/${BASEVM}.img" "${IMG_DIR}/${NEWVM}.img" &> /dev/null
  # 打印绿色的OK
  echo -e "\e[32;1m[OK]\e[0m"
}

# 定义函数，用于修改虚拟机配置文件
function modify_vm_config() {
  # 读取默认的虚拟机配置文件，并将其拷贝到临时文件中
  cat "${IMG_DIR}/.rhel7.xml" > /tmp/myvm.xml
  # 将虚拟机配置文件中所有出现的BASEVM替换为NEWVM
  sed -i "s/${BASEVM}/${NEWVM}/g" /tmp/myvm.xml
  # 生成一个新的UUID，并将虚拟机配置文件中的UUID替换为新的UUID
  sed -i "s/<uuid>.*<\/uuid>/<uuid>$(uuidgen)<\/uuid>/g" /tmp/myvm.xml
  # 将虚拟机配置文件中所有出现的BASEVM.img替换为NEWVM.img
  sed -i "s/${BASEVM}\.img/${NEWVM}\.img/g" /tmp/myvm.xml
  # 将虚拟机配置文件中的MAC地址从a1修改为0c
  sed -i "s/a1/0c/g" /tmp/myvm.xml # 修改 MAC 地址
}

# 定义函数，用于定义新虚拟机并启动
function define_vm() {
  # 将新虚拟机的配置文件定义为一个新的虚拟机，并提示定义结果
  echo -en "定义新的虚拟机......\t\t"
  virsh define /tmp/myvm.xml &> /dev/null
  # 输出一个绿色的"[OK]"
  echo -e "\e[32;1m[OK]\e[0m"
}

# 定义函数，用于创建新虚拟机
function main() {
  # 1. 以时间格式生成VM_NAME
  generate_vm_name

  # 2.调用check_vm_image函数来检查新虚拟机的磁盘镜像是否已经存在
  check_vm_image

  # 3.调用create_vm_image函数来创建新的虚拟机磁盘镜像
  create_vm_image

  # 4.调用modify_vm_config函数来修改新虚拟机的配置文件
  modify_vm_config

  # 5.调用define_vm函数来定义新虚拟机并启动
  define_vm
}


####################################################
# 设置变量，指定新虚拟机的磁盘镜像目录和基础虚拟机名称
IMG_DIR=/var/lib/libvirt/images
BASEVM=rh7_template

# 调用函数来创建新的虚拟机
create_vm

# 退出码：
# 65 -> 用户未输入任何内容
# 66 -> 用户输入的不是数字
# 67 -> 用户输入的数字超出范围
# 68 -> 虚拟机磁盘镜像已经存在