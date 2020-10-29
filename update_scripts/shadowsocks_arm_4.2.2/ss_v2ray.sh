#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
V2RAY_CONFIG_FILE="/koolshare/ss/v2ray.json"


get_latest_version(){
	echo_date "检测V2Ray最新版本..."
    lastver=$(curl --silent "https://api.github.com/repos/gshang2017/V2ray-bin-upx/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//g' )
	if [ -n "$lastver"  ];then
		echo_date "检测到V2Ray最新版本：v$lastver"
		if [ ! -f "/koolshare/bin/v2ray" -o ! -f "/koolshare/bin/v2ctl" ];then
			echo_date "v2ray安装文件丢失！重新下载！"
			oldver="0"
		else
			oldver=`v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g'` || 0
			echo_date "当前已安装V2Ray版本：v$oldver"
		fi
		COMP=`versioncmp $oldver $lastver`
		if [ "$COMP" == "1" ];then
			[ "$oldver" != "0" ] && echo_date "V2Ray已安装版本号低于最新版本，开始更新程序..."
			update_now v$lastver
		else
			V2RAY_LOCAL_VER=`/koolshare/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
			V2RAY_LOCAL_DATE=`/koolshare/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f4`
			[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
			[ -n "$V2RAY_LOCAL_DATE" ] && dbus set ss_basic_v2ray_date="$V2RAY_LOCAL_DATE"
			echo_date "V2Ray已安装版本已经是最新，退出更新程序!"
		fi
	else
		echo_date "获取V2Ray最新版本信息失败！使用备用服务器检测！"
		get_latest_version_backup
	fi
}

get_latest_version_backup(){
	echo_date "目前还没有任何备用服务器！"
	echo_date "获取V2Ray最新版本信息失败！请检查到你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}


update_now(){
	rm -rf /tmp/v2ray_update.zip
	rm -rf /tmp/v2ray
	mkdir -p /tmp/v2ray && cd /tmp/v2ray
	echo_date "开始下载v2ray程序"
	curl  --retry 2  -o /tmp/v2ray_update.zip -L  https://github.com/gshang2017/V2ray-bin-upx/releases/download/v${lastver}/v2ray-linux-arm32-v5-upx.zip
	if [ -f "/tmp/v2ray_update.zip" ];then
		echo_date "v2ray程序下载成功..."
		install_binary
	else
		rm -rf /tmp/v2ray
		echo_date "v2ray下载失败！"
		echo_date "使用备用服务器下载..."
		update_now_backup $1
	fi
}

update_now_backup(){
	echo_date "下载失败，请检查你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}


install_binary(){
	echo_date "开始覆盖最新二进制!"
	if [ "`pidof v2ray`" ];then
		echo_date "为了保证更新正确，先关闭v2ray主进程... "
		killall v2ray >/dev/null 2>&1
		move_binary
		sleep 1
		start_v2ray
	else
		move_binary
	fi
}

move_binary(){
	echo_date "开始替换v2ray二进制文件... "
	unzip -q /tmp/v2ray_update.zip -d /tmp/v2ray
	mv /tmp/v2ray/v2ray /koolshare/bin/v2ray
	mv /tmp/v2ray/v2ctl /koolshare/bin/v2ctl
	mv /tmp/v2ray/geosite.dat /koolshare/bin/geosite.dat
	mv /tmp/v2ray/geoip.dat /koolshare/bin/geoip.dat
	rm -rf /tmp/v2ray
	rm -rf /tmp/v2ray_update.zip
	chmod +x /koolshare/bin/v2*
	V2RAY_LOCAL_VER=`/koolshare/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
	V2RAY_LOCAL_DATE=`/koolshare/bin/v2ray -version 2>/dev/null | head -n 1 | cut -d " " -f5`
	[ -n "$V2RAY_LOCAL_VER" ] && dbus set ss_basic_v2ray_version="$V2RAY_LOCAL_VER"
	[ -n "$V2RAY_LOCAL_DATE" ] && dbus set ss_basic_v2ray_date="$V2RAY_LOCAL_DATE"
	echo_date "v2ray二进制文件替换成功... "
}

start_v2ray(){
	echo_date "开启v2ray进程... "
	cd /koolshare/bin
	export GOGC=30
	v2ray --config=/koolshare/ss/v2ray.json >/dev/null 2>&1 &

	local i=10
	until [ -n "$V2PID" ]
	do
		i=$(($i-1))
		V2PID=`pidof v2ray`
		if [ "$i" -lt 1 ];then
			echo_date "v2ray进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date v2ray启动成功，pid：$V2PID
}

echo_date "==================================================================="
echo_date "                v2ray程序更新(Shell by sadog)"
echo_date "==================================================================="
get_latest_version
echo_date "==================================================================="
