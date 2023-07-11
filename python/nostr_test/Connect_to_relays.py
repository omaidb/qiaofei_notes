
# 参考：https://github.com/jeffthibault/python-nostr

# 导入所需模块
import json  # 用于处理 JSON 数据
from pprint import pprint
import ssl  # 用于处理 SSL 证书
import time  # 用于添加延迟
from nostr.filter import Filter, Filters # 定义和处理事件过滤器，可以用于从中继服务器订阅特定类型的事件。
from nostr.event import Event, EventKind # 自定义模块，用于创建事件
from nostr.relay_manager import RelayManager  # 用于管理中继的自定义模块
from nostr.message_type import ClientMessageType # 自定义模块，用于定义客户端消息类型
from nostr.key import PrivateKey # 自定义模块，用于生成私钥

# 创建一个私钥对象
# private_key = ("nsec1yhalystahd6ndfc7qnu4ccjz4vfn30frxqe2uvwmd8feg2w07uvqp7d9c5")
private_key = ("nsec1wyumvdel8snyq59nf0jq24kazyemdyyv6gdhadmlz4er2f7ghewqfaw9rr")

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
# NOTE: This disables ssl certificate verification
relay_manager.open_connections({"cert_reqs": ssl.CERT_NONE})

# 等待 1.25 秒以确保连接打开
time.sleep(1.25)

# 当消息池中有通知时，循环处理通知
while relay_manager.message_pool.has_notices():
    # 获取下一个通知消息
    notice_msg = relay_manager.message_pool.get_notice()
    # 打印通知消息的内容
    pprint(notice_msg.content)

"""
从中继接收事件
"""
# 创建一个 Filters 对象，用于订阅特定作者的文本笔记
filters = Filters([Filter(authors=["npub1s36lkdvyh45ae5786xem90rm9tdk09c2l4hwgta3pnu24vtq2luqnhyzks"], kinds=[EventKind.TEXT_NOTE])])

# 创建一个字符串，用于标识订阅
subscription_id = ("订阅标识")

# 创建一个请求列表，包含订阅信息和过滤器信息
request = [ClientMessageType.REQUEST, subscription_id]
request.extend(filters.to_json_array())

# 创建一个 RelayManager 对象，并向其添加两个中继服务器
relay_manager = RelayManager()
relay_manager.add_relay("wss://nostr-pub.wellorder.net")
relay_manager.add_relay("wss://relay.damus.io")

# 向 RelayManager 对象中添加订阅信息和过滤器信息
relay_manager.add_subscription(subscription_id, filters)

# 将请求转换为 JSON 格式，并将其发布到中继服务器
message = json.dumps(request)
relay_manager.publish_message(message)


"""
发布事件
"""
# 创建一个事件对象
event = Event("Hello Nostr")
# 并使用私钥对其进行签名
private_key.sign_event(event)

# 将事件发布到中继服务器
relay_manager.publish_event(event)

# 等待 1 秒以确保消息发送完成
time.sleep(1)

# 关闭所有连接
relay_manager.close_connections()