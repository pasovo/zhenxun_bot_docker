import os
import platform
from pathlib import Path

import nonebot
import aiofiles
from nonebot import on_command
from nonebot.rule import to_me
from nonebot.adapters import Bot
from nonebot.params import ArgStr
from nonebot.permission import SUPERUSER
from nonebot_plugin_uninfo import Uninfo
from nonebot.plugin import PluginMetadata

from zhenxun.services.log import logger
from zhenxun.utils.enum import PluginType
from zhenxun.configs.config import BotConfig
from zhenxun.utils.message import MessageUtils
from zhenxun.utils.platform import PlatformUtils
from zhenxun.configs.utils import PluginExtraData

__plugin_meta__ = PluginMetadata(
    name="重启",
    description="执行脚本重启真寻",
    usage="""
    重启
    """.strip(),
    extra=PluginExtraData(
        author="HibiKier", version="0.1", plugin_type=PluginType.SUPERUSER
    ).dict(),
)


_matcher = on_command(
    "重启",
    permission=SUPERUSER,
    rule=to_me(),
    priority=1,
    block=True,
)

driver = nonebot.get_driver()


RESTART_MARK = Path() / "is_restart"

RESTART_FILE = Path() / "restart.sh"

RESTART_GENERATED_FLAG = Path() / "restart"

@_matcher.got(
    "flag",
    prompt=f"确定是否重启{BotConfig.self_nickname}？\n确定请回复[是|好|确定]\n（重启失败咱们将失去联系，请谨慎！）",
)
async def _(bot: Bot, session: Uninfo, flag: str = ArgStr("flag")):
    if flag.lower() in {"true", "是", "好", "确定", "确定是"}:
        await MessageUtils.build_message(
            f"开始重启{BotConfig.self_nickname}..请稍等..."
        ).send()
        async with aiofiles.open(RESTART_MARK, "w", encoding="utf8") as f:
            await f.write(f"{bot.self_id} {session.user.id}")
        logger.info("开始重启真寻...", "重启", session=session)
        if str(platform.system()).lower() == "windows":
            import sys

            python = sys.executable
            os.execl(python, python, *sys.argv)
        else:
            os.system("./restart.sh")  # noqa: ASYNC221
    else:
        await MessageUtils.build_message("已取消操作...").send()


@driver.on_bot_connect
async def _(bot: Bot):
    if str(platform.system()).lower() != "windows":
        if not RESTART_GENERATED_FLAG.exists():
            async with aiofiles.open(RESTART_FILE, "w", encoding="utf8") as f:
                await f.write(f"""#!/bin/bash

pid=$(netstat -tunlp 2>/dev/null | grep {str(bot.config.port)} | awk '{{print $7}}' | cut -d'/' -f1)
if [[ -n "$pid" ]]; then
    echo "正在杀死占用端口 {str(bot.config.port)} 的进程 $pid"
    kill -9 $pid
    echo "等待进程 $pid 退出..."
    wait $pid 2>/dev/null || sleep 2 
else
    echo "没有进程占用端口 {str(bot.config.port)}"
fi

# 再次检查端口是否被释放
if netstat -tunlp 2>/dev/null | grep -q {str(bot.config.port)}; then
    echo "端口仍被占用，无法启动 bot.py"
    exit 1
fi

# 检测是否在虚拟环境中
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "检测到当前在虚拟环境中，直接运行"
    python3 bot.py 2>&1 | tee bot_error.log
else
    echo "未检测到虚拟环境，使用 poetry 运行"
    poetry run python3 bot.py 2>&1 | tee bot_error.log
fi

echo "done"

""")
            os.system("chmod +x ./restart.sh")
            RESTART_GENERATED_FLAG.touch()
            logger.info("已自动生成 restart.sh 文件， 检查脚本是否与本地指令符合...")
    if RESTART_MARK.exists():
        async with aiofiles.open(RESTART_MARK, encoding="utf8") as f:
            bot_id, user_id = (await f.read()).split()
        if bot := nonebot.get_bot(bot_id):
            if target := PlatformUtils.get_target(bot, user_id):
                await MessageUtils.build_message(
                    f"{BotConfig.self_nickname}已成功重启！"
                ).send(target, bot=bot)
        RESTART_MARK.unlink()
