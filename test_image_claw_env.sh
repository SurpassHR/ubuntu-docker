# !/bin/bash

# 删除挂载点
rm -rf ./mapdata

# 删除无用容器
docker container rm -f $(docker container list -q)
docker rmi -f $(docker images -q)

# 构建镜像
docker build -t test_image_claw_env . -D

# 运行容器
# 注意：所有 docker run 的选项 (如 -d, -p) 都必须在镜像名称之前。
docker run \
    -d \
    -p 10086:10086 \
    -p 8000:8000 \
    -p 2222:22 \
    -v ./mapdata:/home/hr0530 \
    -e "SSH_USER=hr0530" \
    -e "SSH_PASSWORD=000530" \
    -e "GEMINI_BALANCE_ENV_TYPE=claw" \
    --name test_env_container \
    test_image_claw_env

docker logs -f test_env_container