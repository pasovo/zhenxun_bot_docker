# 第一阶段：生成依赖
FROM python:3.11-bookworm AS requirements-stage

WORKDIR /tmp

RUN pip install poetry && \
    poetry self add poetry-plugin-export

COPY pyproject.toml poetry.lock* /tmp/

RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# 第二阶段：构建依赖
FROM python:3.11-bookworm AS build-stage

WORKDIR /wheel

COPY --from=requirements-stage /tmp/requirements.txt /wheel/requirements.txt
RUN pip wheel --wheel-dir=/wheel --no-cache-dir --requirement /wheel/requirements.txt

# 第三阶段：运行
FROM python:3.11-slim-bookworm

WORKDIR /app/zhenxun

ENV TZ=Asia/Shanghai PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y --no-install-recommends \
    curl fontconfig fonts-noto-color-emoji \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install poetry && poetry self add poetry-plugin-export

ENV PATH="$HOME/.local/bin:$PATH"

COPY --from=build-stage /wheel /wheel
COPY . .

RUN pip install --no-cache-dir --no-index --find-links=/wheel -r /wheel/requirements.txt && rm -rf /wheel

RUN pip install playwright && playwright install --with-deps chromium

EXPOSE 8080

VOLUME ["/app/zhenxun/data", "/app/zhenxun/resources", "/app/zhenxun/log"]

RUN chmod +x ./restart.sh

CMD ["./restart.sh"]
