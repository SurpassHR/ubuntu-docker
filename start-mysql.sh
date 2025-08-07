#!/bin/bash
set -e

# 定义 MySQL 数据目录
DATADIR=/home/hr0530/mysql

# 检查数据目录是否已经初始化
# 我们通过检查 'mysql' 子目录是否存在来判断
if [ ! -d "$DATADIR/mysql" ]; then
    echo "MySQL data directory not found. Initializing..."
    # The directory is now created and chowned by entrypoint.sh.
    # We just need to initialize the database if it's empty.
    mysqld --initialize-insecure --user=mysql --datadir="$DATADIR"
    echo "MySQL data directory initialized."
else
    echo "MySQL data directory already exists."
fi

# 使用 exec 来让 mysqld 进程替换当前的 shell 进程
# 这使得 supervisord 可以直接管理 mysqld 进程
echo "Starting MySQL daemon..."
exec /usr/sbin/mysqld --datadir="$DATADIR" --user=mysql