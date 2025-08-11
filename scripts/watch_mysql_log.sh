#!/bin/sh
# 这个脚本持续监控 MySQL 错误日志，并为每一行添加前缀

# 等待 /var/log/mysql/error.log 文件创建
while [ ! -f /var/log/mysql/error.log ]; do
    echo "Waiting for MySQL error log file to be created..."
    sleep 1
done

# 开始监控
exec tail -f /var/log/mysql/error.log | sed 's/^/[🗄️ mysql]: /' > /dev/stdout