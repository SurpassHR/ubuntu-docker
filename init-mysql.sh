#!/bin/bash
# 目标数据目录
MYSQL_DATA="/home/hr0530/mysql"

echo "[1/6] 修改 mysql 用户 home 目录..."
usermod -d $MYSQL_DATA mysql

echo "[2/6] 创建并授权数据目录..."
mkdir -p $MYSQL_DATA
chown -R mysql:mysql $MYSQL_DATA
chmod 777 $MYSQL_DATA

echo "[3/6] 修改 MySQL 配置文件..."
CONF_FILE=$(find /etc/mysql /etc -type f -name "mysqld.cnf" 2>/dev/null | head -n 1)
if [ -n "$CONF_FILE" ]; then
    sed -i "s|^# datadir\s*=.*|datadir = $MYSQL_DATA|" "$CONF_FILE"
    echo "/home/hr0530/mysql/ r," >> /etc/apparmor.d/usr.sbin.mysqld
    echo "/home/hr0530/mysql/** rwk," >> /etc/apparmor.d/usr.sbin.mysqld
    apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld
    echo "配置文件已修改: $CONF_FILE"
else
    echo "未找到 mysqld.cnf，请手动修改 MYSQL_DATA 配置"
fi

echo "[4/6] 初始化数据目录..."
mysqld --initialize-insecure --user=mysql --datadir=$MYSQL_DATA

echo "[5/6] 启动 MySQL 服务..."
service mysql start

echo "[6/6] 验证 MySQL 启动状态..."
if pgrep mysqld &> /dev/null; then
    mysql -u root < /tmp/init.sql
    echo "✅ MySQL 启动成功！你可以用以下命令登录："
    echo "   mysql -uroot"
else
    echo "❌ MySQL 启动失败，请查看日志："
    echo "   sudo cat /var/log/mysql/error.log"
fi