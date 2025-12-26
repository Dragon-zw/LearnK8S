#!/bin/bash
# MySQL 安全配置脚本

echo "=========================================="
echo "MySQL 安全配置向导"
echo "=========================================="
echo ""

# 提示用户输入 root 密码
read -sp "请输入 MySQL root 用户的新密码: " ROOT_PASSWORD
echo ""
read -sp "请再次确认密码: " ROOT_PASSWORD_CONFIRM
echo ""

if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
    echo "错误: 两次输入的密码不一致！"
    exit 1
fi

# 设置 root 密码
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✓ Root 密码设置成功"
else
    echo "✗ Root 密码设置失败"
    exit 1
fi

# 运行安全配置
echo ""
echo "正在运行 MySQL 安全配置..."
mysql_secure_installation <<EOF
${ROOT_PASSWORD}
y
y
y
y
y
EOF

echo ""
echo "=========================================="
echo "MySQL 安全配置完成！"
echo "=========================================="
echo ""
echo "MySQL 服务状态:"
systemctl status mysqld --no-pager -l
echo ""
echo "连接 MySQL 的命令:"
echo "mysql -u root -p"
echo ""

