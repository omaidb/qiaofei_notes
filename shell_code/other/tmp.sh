#!/usr/bin/env bash

set -ex

# 定义全局变量
SERVERS_FILE="$HOME/xsync.txt"  # 服务器列表文件路径
LOG_FILE="/var/log/xsync.log"  # 日志文件路径

# 定义数组变量
ITEMS=()  # 待同步文件或目录列表

# 定义日志函数
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $*" | tee -a "$LOG_FILE"
  # 打印带时间戳的日志内容，并将日志输出到日志文件和终端
}

# 定义错误处理函数
die() {
  log "ERROR: $*"
  exit 1
  # 打印错误信息，并退出脚本
}

# 检查文件是否存在
check_server_file(){
    # 判断服务器列表文件是否存在，不存在则创建
    if ! test -f "$SERVERS_FILE"; then
       touch "$SERVERS_FILE"
    fi
}

# 检查依赖项是否已安装
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    log "正在安装 $1..."
    if ! { apt-get -qq -y install "$1" || yum -q -y install "$1"; } &>/dev/null; then
      die "安装 $1 失败"
    fi
  fi
  # 检查指定的依赖项是否已经安装，如果没有则安装
}

# 定义帮助函数
usage() {
  echo "使用方法: xsync [-h] [ITEM...]"
  echo "同步文件或目录到远程服务器"
  echo ""
  echo "选项:"
  echo "  -h, --help          显示帮助信息并退出"
  echo ""
  echo "参数:"
  echo "  ITEM                待同步的文件或目录"
}

# 解析命令行参数
parse_args() {
  while [[ $# -gt 0 ]]; do  # 使用 while 循环遍历命令行参数
    case $1 in
      -h|--help)  # 如果参数是 -h 或 --help，则打印使用方法并退出脚本
        usage
        exit
        ;;
      *)
        ITEMS+=("$1")  # 否则，将参数保存到 ITEMS 数组变量中
        ;;
    esac
    shift  # 移除已经处理的参数
  done

  if [[ ${#ITEMS[@]} -eq 0 ]]; then  # 如果没有指定待同步的文件或目录，则打印使用方法并退出脚本
    usage
    exit 1
  fi
}

# 同步单个文件或目录到远程服务器
sync_item() {
  local item="$1"  # 待同步的文件或目录路径
  local server="$2"  # 远程服务器地址

  log "正在同步 $item 到 $server..."
  rsync -aSHP "$item" "$server:$item"
  # 使用 rsync 命令将本地文件或目录同步到远程服务器
}

# 同步多个文件和目录到多个远程服务器
sync_items() {
  local items=("${ITEMS[@]}")  # 待同步的本地文件或目录列表
  local servers=()  # 目标服务器列表

  # 从服务器列表文件中读取服务器列表，保存到 servers 数组变量中
  while read -r server; do
    servers+=("$server")
  done < "$SERVERS_FILE"

  if [[ ${#servers[@]} -eq 0 ]]; then  # 如果服务器列表为空，则退出脚本
    die "在服务器列表文件中未找到任何服务器"
  fi

  # 遍历每个目标服务器，并将每个本地文件或目录同步到目标服务器上
  for server in "${servers[@]}"; do
    log "正在同步到 $server..."
    for item in "${items[@]}"; do
      if [[ ! -e "$item" ]]; then  # 如果待同步的文件或目录不存在，则打印一条错误信息并跳过该文件或目录
        log "$item 不存在"
        continue
      fi

      sync_item "$item" "$server"  # 同步本地文件或目录到目标服务器
    done
  done
}

# 检查依赖项是否已安装
check_dependency rsync

# 检查服务器列表文件是否存在
check_server_file

# 解析命令行参数
parse_args "$@"

# 同步多个文件和目录到多个远程服务器
sync_items