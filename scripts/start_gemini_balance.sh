#!/bin/bash

# 等待 MySQL 启动完成
while ! mysqladmin ping -h 127.0.0.1 --silent; do
    echo "Waiting for MySQL to start..."
    sleep 1
done

# 等待 gemini-balance 目录创建完成
while [ ! -d "/home/hr0530/apps/gemini-balance" ]; do
    echo "Waiting for gemini-balance directory to be created..."
    sleep 1
done

# 初始化数据库
echo "MySQL is ready. Initializing database..."
mysql -u root < /tmp/init.sql

# 进入 gemini-balance 目录
cd /home/hr0530/apps/gemini-balance

# 进入 Python 虚拟环境
python -m venv .venv
source .venv/bin/activate
echo "Installing requirements..."
pip install -r requirements.txt 2>&1 > /dev/null
echo "Requirements installed."

# 若 $GEMINI_BALANCE_ENV_TYPE 为 docker 则复制 .docker.env 到 .env
# 若 $GEMINI_BALANCE_ENV_TYPE 为 claw 则复制 .claw.env 到 .env
if [ "$GEMINI_BALANCE_ENV_TYPE" = "docker" ]; then
    cp .docker.env .env
elif [ "$GEMINI_BALANCE_ENV_TYPE" = "claw" ]; then
    cp .claw.env .env
fi

# 运行应用
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload