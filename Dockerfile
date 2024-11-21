FROM python:3.11-slim-bookworm

EXPOSE 8080

WORKDIR /app/zhenxun

COPY . /app/zhenxun

RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
    net-tools \
    gcc \
    g++ && \
    apt clean

RUN pip install poetry 

RUN poetry install

VOLUME /app/zhenxun/data /app/zhenxun/data
VOLUME /app/zhenxun/resources /app/zhenxun/resources
VOLUME /app/zhenxun/.env.dev /app/zhenxun/.env.dev
VOLUME /app/zhenxun/restart.sh /app/zhenxun/restart.sh

RUN poetry run playwright install --with-deps chromium

RUN chmod +x ./restart.sh

CMD ["./restart.sh"]
