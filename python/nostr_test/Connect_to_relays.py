# 导入所需模块
import json # 用于处理 JSON 数据
from pprint import pprint  
import ssl  # 用于处理 SSL 证书
import time  # 用于添加延迟
from nostr.relay_manager import RelayManager  # 用于管理中继的自定义模块

# 创建 RelayManager 类的实例
relay_manager = RelayManager()

with open('nostr_test/relay.txt', mode='r', encoding='utf-8') as f:
    lines = f.readlines()  # 读取所有行数据
    # 循环读取每一行数据
    for line in lines:
        line = line.strip()  # 去除每行的换行符和空格
        # 向管理器的列表中添加中继服务器
        relay_manager.add_relay(f"wss://{line}")

# 打开连接并禁用 SSL 证书验证
relay_manager.open_connections({"cert_reqs": ssl.CERT_NONE}) # NOTE: This disables ssl certificate verification

# 等待 1.25 秒以确保连接打开
time.sleep(1.25)

# 当消息池中有通知时，循环处理通知
while relay_manager.message_pool.has_notices():
    # 获取下一个通知消息
    notice_msg = relay_manager.message_pool.get_notice()
    # 打印通知消息的内容
    pprint(notice_msg.content)

# 关闭所有连接
relay_manager.close_connections()