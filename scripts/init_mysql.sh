#!/bin/bash
# 目标数据目录
MYSQL_DATA="/home/hr0530/mysql"

echo "[1/4] 修改 mysql 用户 home 目录..."
usermod -d $MYSQL_DATA mysql

echo "[2/4] 创建并授权数据目录..."
mkdir -p $MYSQL_DATA
chown -R mysql:mysql $MYSQL_DATA
chmod 777 $MYSQL_DATA

echo "[3/4] 修改 MySQL 配置文件..."
CONF_FILE=$(find /etc/mysql /etc -type f -name "mysqld.cnf" 2>/dev/null | head -n 1)
if [ -n "$CONF_FILE" ]; then
    sed -i "s|^# datadir\s*=.*|datadir = $MYSQL_DATA|" "$CONF_FILE"
    # echo "/home/hr0530/mysql/ r," >> /etc/apparmor.d/usr.sbin.mysqld
    # echo "/home/hr0530/mysql/** rwk," >> /etc/apparmor.d/usr.sbin.mysqld
    # apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld
    echo "配置文件已修改: $CONF_FILE"
else
    echo "未找到 mysqld.cnf，请手动修改 MYSQL_DATA 配置"
fi

echo "[4/4] 初始化数据目录..."
mysqld --initialize-insecure --user=mysql --datadir=$MYSQL_DATA