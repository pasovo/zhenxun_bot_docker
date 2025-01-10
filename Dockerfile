# 第一阶段：生成依赖
FROM python:3.11-bookworm AS requirements-stage

WORKDIR /tmp

# 安装 Poetry 并添加导出插件
ENV POETRY_HOME="/opt/poetry" PATH="${PATH}:/opt/poetry/bin"
RUN curl -sSL https://install.python-poetry.org | python - -y && \
    poetry self add poetry-plugin-export

# 复制 pyproject.toml 和 poetry.lock
COPY ./pyproject.toml ./poetry.lock* /tmp/

# 导出依赖到 requirements.txt
RUN poetry export \
    -f requirements.txt \
    --output requirements.txt \
    --without-hashes \
    --without-urls

# 第二阶段：构建轮子包
FROM python:3.11-bookworm AS build-stage

WORKDIR /wheel

# 复制依赖文件并生成轮子包
COPY --from=requirements-stage /tmp/requirements.txt /wheel/requirements.txt
RUN pip wheel --wheel-dir=/wheel --no-cache-dir --requirement /wheel/requirements.txt

# 第三阶段：获取版本信息（可选）
FROM python:3.11-bookworm AS metadata-stage

WORKDIR /tmp

# 从 Git 获取版本信息
RUN --mount=type=bind,source=./.git/,target=/tmp/.git/ \
    git describe --tags --exact-match > /tmp/VERSION 2>/dev/null || \
    git rev-parse --short HEAD > /tmp/VERSION && \
    echo "Building version: $(cat /tmp/VERSION)"

# 最终阶段：运行镜像
FROM python:3.11-slim-bookworm

WORKDIR /app/zhenxun

# 环境变量
ENV TZ=Asia/Shanghai PYTHONUNBUFFERED=1

# 暴露端口
EXPOSE 8080

# 安装系统依赖
RUN apt update && \
    apt install -y --no-install-recommends curl fontconfig fonts-noto-color-emoji && \
    apt clean && \
    fc-cache -fv && \
    apt-get purge -y --auto-remove curl && \
    rm -rf /var/lib/apt/lists/*

# 安装 Poetry（运行时需要使用）
ENV POETRY_HOME="/opt/poetry" PATH="${PATH}:/opt/poetry/bin"
RUN curl -sSL https://install.python-poetry.org | python - -y && \
    poetry self add poetry-plugin-export

# 复制轮子包和应用代码
COPY --from=build-stage /wheel /wheel
COPY . .

# 安装依赖
RUN pip install --no-cache-dir --no-index --find-links=/wheel -r /wheel/requirements.txt && rm -rf /wheel

# 安装 Playwright 和其依赖
RUN poetry run playwright install --with-deps chromium && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# 复制版本信息（可选）
COPY --from=metadata-stage /tmp/VERSION /app/VERSION

# 配置数据卷
VOLUME ["/app/zhenxun/data", "/app/zhenxun/resources", "/app/zhenxun/log"]

# 启动命令
CMD ["poetry", "run", "python", "bot.py"]
