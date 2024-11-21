#!/bin/bash

# 加载 .env.dev 文件中的 PORT 变量
if [ -f .env.dev ]; then
    export $(grep -oP '^PORT=\K.+' .env.dev)  # 提取并导出 PORT 变量
else
    echo ".env.dev 文件不存在。"
    exit 1
fi

# 检查是否占用端口，使用从 .env.dev 加载的 PORT 值
pid=$(netstat -tunlp 2>/dev/null | grep $PORT | awk '{print $7}' | cut -d'/' -f1)

if [[ -n "$pid" ]]; then
    echo "正在杀死占用端口 $PORT 的进程 $pid"
    kill -9 $pid
    echo "等待进程 $pid 退出..."
    wait $pid 2>/dev/null || sleep 2  # 确保进程结束或等待一段时间
else
    echo "没有进程占用端口 $PORT，好耶"
fi

# 再次检查端口是否被释放
if netstat -tunlp 2>/dev/null | grep -q $PORT; then
    echo "端口 $PORT 仍被占用，重启镜像吧~"
    exit 1
fi

# 检测是否在虚拟环境中
if [[ -n "$VIRTUAL_ENV" ]]; then
    python3 bot.py
else
    poetry run python3 bot.py
fi

echo "done"
