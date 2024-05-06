#!/bin/bash
# 自动链接克隆 KVM 虚拟机的脚本，适用于生产环境

# 开启debug
set -ex

# 配置
vm_name="myvm" # 源虚拟机的名称
clone_prefix="clone-" # 克隆虚拟机名称的前缀
clone_count=5 # 要创建的克隆虚拟机的数量
clone_memory="4G" # 每个克隆虚拟机的内存大小（例如 "2G"、"4096"）
clone_vcpus=2 # 每个克隆虚拟机的虚拟 CPU 数量
clone_disk_size="20G" # 每个克隆虚拟机的磁盘镜像文件大小（例如 "10G"、"100GiB"）

# 获取源虚拟机的磁盘镜像文件名和目录
function get_source_disk() {
  src_vm_name_disk=$(virsh dumpxml "$vm_name" | grep 'source file' | awk -F "'" '{print $2}')
  src_disk_dir=$(dirname "$src_vm_name_disk")
}

# 创建一个克隆虚拟机
function create_clone_vm() {
  # 克隆磁盘镜像文件
  qemu-img create -f qcow2 -b "$src_vm_name_disk" -o size="$clone_disk_size" "$clone_vm_disk"

  # 为克隆虚拟机生成新的 XML 配置文件
  clone_vm_xml=$(mktemp)
  virsh dumpxml "$vm_name" | sed "s/<name>$vm_name<\/name>/<name>$clone_name<\/name>/" > "$clone_vm_xml"

  # 修改克隆虚拟机的 XML 配置文件
  sed -i "s/<uuid>.*<\/uuid>/<uuid>$(uuidgen)<\/uuid>/" "$clone_vm_xml"
  sed -i "s/<memory unit='KiB'>.*<\/memory>/<memory unit='GiB'>$clone_memory<\/memory>/" "$clone_vm_xml"
  sed -i "s/<currentMemory unit='KiB'>.*<\/currentMemory>/<currentMemory unit='GiB'>$clone_memory<\/currentMemory>/" "$clone_vm_xml"
  sed -i "s/<vcpu placement='static'>.*<\/vcpu>/<vcpu placement='static'>$clone_vcpus<\/vcpu>/" "$clone_vm_xml"
  sed -i "s/<source file='.*.qcow2'\/>/<source file='$clone_vm_disk'\/>/" "$clone_vm_xml"
  sed -i "s/<target dev='vda' bus='virtio'\/>/<target dev='vda' bus='virtio'\/><address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'\/>/" "$clone_vm_xml"

  # 使用修改后的 XML 配置文件定义克隆虚拟机
  virsh define "$clone_vm_xml"

  echo "已完成克隆虚拟机 '$vm_name' 为 '$clone_name' 的创建。"
}

# 创建多个克隆虚拟机
function create_multiple_clones() {
  # 循环创建指定数量的克隆虚拟机
  for ((i=1; i<=clone_count; i++)); do
    clone_name="${clone_prefix}${i}"
    clone_vm_disk=${src_disk_dir}/${clone_name}.qcow2

    create_clone_vm
  done
}

# 调用函数创建克隆虚拟机
get_source_disk
create_multiple_clones

# 这个脚本从指定的源虚拟机中克隆指定数量的虚拟机，并为每个虚拟机生成新的 XML 配置文件。虚拟机的名称、内存大小、CPU 数量和磁盘镜像大小都可以在脚本中进行配置