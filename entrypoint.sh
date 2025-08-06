#!/bin/sh
#
# 这是一个为 Docker-in-Docker (dind) 环境设计的入口点脚本。
# 它首先在后台启动 Docker 守护进程，然后执行传递给容器的任何命令 (CMD 或 docker run 参数)。
#

set -e

# 启动 Docker 守护进程。
# --host 用于指定守护进程监听的地址。
# unix:///var/run/docker.sock 是标准的 Docker socket。
# tcp://0.0.0.0:2375 允许通过 TCP 连接到 Docker 守护进程（例如从其他容器或外部）。
# '&' 使其在后台运行。
dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 &

# 等待 Docker 守护进程完全启动并准备好接收连接。
# 这个循环会一直尝试执行 `docker info`，直到命令成功返回。
# 这样可以确保后续的 docker 命令不会因为守护进程尚未就绪而失败。
while ! docker info > /dev/null 2>&1; do
  echo "正在等待 Docker 守护进程启动..."
  sleep 1
done
echo "Docker 守护进程已成功启动。"

# 执行传递给容器的命令 (CMD)。
# `exec "$@"` 会将脚本的执行权交给 CMD 中指定的命令。
# 这使得容器的行为可以像没有这个入口点脚本一样，同时又能享受到预启动的 Docker 服务。
exec "$@"