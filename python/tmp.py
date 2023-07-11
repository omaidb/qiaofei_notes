with open('./nostr_test/relay.txt', mode='r', encoding='utf-8') as f:
    lines = f.readlines()  # 读取所有行数据
    # 循环读取每一行数据
    for line in lines:
        line = line.strip()  # 去除每行的换行符和空格
        print(line)  # 处理每行数据，例如打印或者存储到其他文件中
f.close()  # 关闭文件