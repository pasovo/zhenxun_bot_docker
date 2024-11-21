# zhenxun_bot_docker 
来源https://github.com/HibiKier/zhenxun_bot

感谢大佬写出如此可爱的小真寻

代码几乎全部来自于chatgpt

使用此代码默认你会使用docker，不会你问我我也不会（逃

### 已知bug：

webui几乎不能使用

~~重启命令有问题~~ 已经修复，现在重启应该不会出问题

其他待测试，有bug提issue，有时间会修的

## 使用方式
因为我只用docker compose，所以这里也只提供docker compose~
 ```
version: '3.8'

services:
  zhenxun-docker:
    image: registry.cn-hangzhou.aliyuncs.com/starfishes/zhenxun-docker
    ports:
      - "8080:8080"
    container_name: zhenxun-docker
    network_mode: bridge
    volumes:
      - ./.env.dev:/app/zhenxun/.env.dev
      - ./data:/app/zhenxun/data
      - ./resources:/app/zhenxun/resources 
      - ./log:/app/zhenxun/log
      - ./zhenxun/plugins:/app/zhenxun/zhenxun/plugins （插件目录，非必须
    restart: no
```
