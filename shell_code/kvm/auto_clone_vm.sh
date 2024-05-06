#!/usr/bin/env bash

# 开启debug
set -ex

# 将获取源vm实例、新vm实例名称
function parse_arguments() {
  # 如果没有传入足够的参数，输出使用说明并退出
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <src_vm_name> <new_vm_name>"
    exit 1
  fi

  # 获取源vm实例名称，赋值给全局变量 $src_vm_name
  src_vm_name=$1

  # 获取新vm实例名称，赋值给全局变量 $new_vm_name
  new_vm_name=$2

  # 设置新vm实例配置文件的路径和文件名，赋值给全局变量 $new_vm_xml
  new_vm_xml="/tmp/${new_vm_name}.xml"

  # 生成新vm实例的uuid，赋值给全局变量 $new_vm_uuid
  new_vm_uuid=$(uuidgen)
}

# 将从源vm实例导出配置到新vm实例配置文件的代码封装为函数
function export_vm_config() {
  # 从源vm实例导出配置到新vm实例配置文件
  virsh dumpxml "$src_vm_name" >"$new_vm_xml"
}

# 将从新vm实例配置文件中过滤出磁盘完整路径的代码封装为函数
function get_vm_disk_path() {
  # 从新vm实例配置文件中过滤出磁盘完整路径
  src_vm_name_disk=$(grep qcow2 "$new_vm_xml" | awk -F "'" '/source file/{print $2}')

  # 读取src_disk所在的目录
  src_disk_dir=$(dirname "$src_vm_name_disk")

  # 拼接出新vm实例的磁盘完整路径，赋值给全局变量 $new_vm_disk
  new_vm_disk=${src_disk_dir}/${new_vm_name}.qcow2
}

# 将创建基于链接克隆的虚拟磁盘文件的代码封装为函数
function clone_vm_disk() {
  # 创建基于链接克隆的虚拟磁盘文件
  qemu-img create -f qcow2 -b "$src_vm_name_disk" "$new_vm_disk"
}

# 将修改新虚拟机的xml配置文件的代码封装为函数
function modify_vm_config() {
  # 修改新虚拟机的xml配置文件
  sed -i 's/vmname/'"$new_vm_xml"'/' "$new_vm_xml"
  sed -i 's/vmuuid/'"$new_vm_uuid"'/' "$new_vm_xml"
  sed -i '/mac address/d' "$new_vm_xml"
  sed -i '2s#'"$src_vm_name"'#'"$new_vm_name"'#' "$new_vm_xml"
  sed -i 's#'"$src_vm_name_disk"'#'"$new_vm_disk"'#g' "$new_vm_xml"
  sed -i '/\/var\/lib\/libvirt\/qemu\/channel\/target/d' "$new_vm_xml"
}

# 将导入新vm实例的虚拟机配置文件的代码封装为函数
function import_vm_config() {
  # 导入新vm实例的虚拟机配置文件
  virsh define "$new_vm_xml"
}

# 将测试启动新vm实例的代码封装为函数
function start_vm() {
  # 测试启动新vm实例
  virsh start "$new_vm_name"
}

# 主函数，调用上述函数组合实现整个脚本的功能
function main() {
  echo "本脚本只在Centos7测试过"

  # 解析命令行参数
  parse_arguments "$@"

  # 导出源vm实例的配置到新vm实例的配置文件
  export_vm_config

  # 获取源vm实例的磁盘路径并生成新vm实例的磁盘路径
  get_vm_disk_path

  # 创建基于链接克隆的虚拟磁盘文件
  clone_vm_disk

  # 修改新vm实例的xml配置文件
  modify_vm_config

  # 导入新vm实例的虚拟机配置文件
  import_vm_config

  # 测试启动新vm实例
  start_vm
}

# 调用主函数
main "$@"