#!/usr/bin/env bash
set -e
# 服务端脚本
# rvm 环境
source ~/.profile
export RAILS_ENV=production
project=$1
compress=${project}.tar.gz

if [[ -d ${project} ]];then
	echo "服务器已存在该项目，开始更新...."
	cd ${project}
	pid=`cat shared/pids/puma.pid`
	if [[ -d /proc/${pid} ]];then
		kill ${pid}
	fi
	cd ..
fi

# 解压
echo "开始解压...."
tar xzf ${compress}
rm -rf ${compress}

cd ${project}
# 数据库迁移
echo "运行数据库迁移...."
bundle exec rails db:migrate > /dev/null

# 必要文件夹
mkdir -p shared/log shared/pids shared/sockets

# 运行服务器
echo "启动服务器...."
puma

echo "服务器启动成功"