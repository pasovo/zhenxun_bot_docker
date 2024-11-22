#!/bin/bash

pid=$(netstat -tunlp 2>/dev/null | grep PORT | awk '{print $7}' | cut -d'/' -f1)
if [[ -n "$pid" ]]; then
    echo "正在杀死占用端口 PORT 的进程 $pid"
    kill -9 $pid
    echo "等待进程 $pid 退出..."
    wait $pid 2>/dev/null || sleep 2  # 确保进程结束或等待一段时间
else
    echo "没有进程占用端口 PORT"
fi

# 再次检查端口是否被释放
if netstat -tunlp 2>/dev/null | grep -q PORT; then
    echo "端口 PORT 仍被占用，无法启动 bot.py"
    exit 1
fi

# 检测是否在虚拟环境中
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "检测到当前在虚拟环境中，直接运行 python3 bot.py..."
    python3 bot.py 2>&1 | tee bot_error.log
else
    echo "未检测到虚拟环境，使用 poetry 运行 bot.py..."
    poetry run python3 bot.py 2>&1 | tee bot_error.log
fi

echo "done"