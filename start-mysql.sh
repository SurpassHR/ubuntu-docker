#!/bin/bash
set -e

# 定义 MySQL 数据目录
DATADIR=/home/hr0530/mysql

# 检查数据目录是否已经初始化
# 我们通过检查 'mysql' 子目录是否存在来判断
if [ ! -d "$DATADIR/mysql" ]; then
    echo "MySQL data directory not found. Initializing..."

    # 确保数据目录存在且权限正确
    mkdir -p "$DATADIR"
    chown -R mysql:mysql "$DATADIR"

    # 使用 --initialize-insecure 进行初始化，这不会生成随机的 root 密码
    # 在开发环境中这通常是可接受的。如果需要密码，可以使用 --initialize
    mysqld --initialize-insecure --user=mysql --datadir="$DATADIR"
    echo "MySQL data directory initialized."
else
    echo "MySQL data directory already exists."
fi

# 使用 exec 来让 mysqld 进程替换当前的 shell 进程
# 这使得 supervisord 可以直接管理 mysqld 进程
echo "Starting MySQL daemon..."
exec /usr/sbin/mysqld --datadir="$DATADIR" --user=mysql