#!/bin/bash

# 进入 gemini-balance 目录
cd /home/hr0530/apps/gemini-balance

# 进入 Python 虚拟环境
source .venv/bin/activate

# 若 $GEMINI_BALANCE_ENV_TYPE 为 docker 则复制 .docker.env 到 .env
# 若 $GEMINI_BALANCE_ENV_TYPE 为 claw 则复制 .claw.env 到 .env
if [ "$GEMINI_BALANCE_ENV_TYPE" = "docker" ]; then
    cp .docker.env .env
elif [ "$GEMINI_BALANCE_ENV_TYPE" = "claw" ]; then
    cp .claw.env .env
fi

# 运行应用
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload