#!/bin/bash

# 等待 MySQL 启动完成
echo "Waiting for MySQL to start..."
until mysql -u root -e "SELECT 1;" &> /dev/null; do
    echo "Waiting for MySQL..."
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
pip install -r requirements.txt > /dev/null 2>&1

# 若 $GEMINI_BALANCE_ENV_TYPE 为 docker 则复制 .docker.env 到 .env
# 若 $GEMINI_BALANCE_ENV_TYPE 为 claw 则复制 .claw.env 到 .env
if [ "$GEMINI_BALANCE_ENV_TYPE" = "docker" ]; then
    cp .docker.env .env
elif [ "$GEMINI_BALANCE_ENV_TYPE" = "claw" ]; then
    cp .claw.env .env
fi

# 运行应用
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload