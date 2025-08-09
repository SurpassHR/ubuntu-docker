# 构建镜像
docker build -t test_image_claw_env .

# 运行容器
# 注意：所有 docker run 的选项 (如 -d, -p) 都必须在镜像名称之前。
docker run \
    -d \
    -p 10086:10086 \
    -p 8000:8000 \
    -v ./mapdata:/home/hr0530 \
    -e "SSH_USER=hr0530" \
    -e "SSH_PASSWORD=000530" \
    -e "GEMINI_BALANCE_ENV_TYPE=claw" \
    --name test_env_container \
    test_image_claw_env