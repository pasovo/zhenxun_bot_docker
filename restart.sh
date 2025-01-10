#!/bin/bash

# 获取占用端口的进程 ID
pid=$(ss -tunlp 2>/dev/null | grep ':8989' | awk '{print $7}' | cut -d',' -f2 | cut -d'/' -f1)

POETRY_PATH="$HOME/.local/bin/poetry"

if [[ -n "$pid" ]]; then
    echo "正在杀死占用端口 8989 的进程 $pid"
    kill -9 "$pid"
    echo "等待进程 $pid 退出..."
    sleep 2
else
    echo "没有进程占用端口 8989"
fi

# 再次检查端口是否被释放
if ss -tunlp 2>/dev/null | grep -q ':8989'; then
    echo "端口 8989 仍被占用，无法启动 bot.py"
    exit 1
fi

# 检测是否在虚拟环境中
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "检测到当前在虚拟环境中，直接运行 python3 bot.py..."
    python3 bot.py 2>&1 | tee bot_error.log
else
    if command -v poetry &>/dev/null; then
        echo "未检测到虚拟环境，使用 poetry 运行 bot.py..."
        "$POETRY_PATH" run python3 bot.py 2>&1 | tee bot_error.log
    else
        echo "未检测到虚拟环境，也未安装 poetry，无法运行 bot.py"
        exit 1
    fi
fi

# 检查 bot.py 是否成功启动
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "bot.py 启动失败，请检查 bot_error.log"
    exit 1
fi

echo "服务启动成功"
