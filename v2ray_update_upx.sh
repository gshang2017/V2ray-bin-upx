#!/bin/sh

lastver=$(curl --silent "https://api.github.com/repos/v2fly/v2ray-core/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )
oldver=$(curl --silent "https://api.github.com/repos/gshang2017/V2ray-bin-upx/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )
if [ -n "$lastver" ]; then
    if [ "$lastver" != "$oldver" ]; then
        echo "准备下载最新版本，并用upx压缩"
        wget --no-check-certificate --timeout=8 --tries=3 -O - "https://github.com/v2fly/v2ray-core/releases/download/${lastver}/v2ray-linux-arm32-v5.zip" > /tmp/v2ray_update.zip
        if [ -f "/tmp/v2ray_update.zip" ]; then
            mkdir -p /tmp/v2ray_update
            unzip /tmp/v2ray_update.zip -d /tmp/v2ray_update
            #压缩v2ray v2ctl
            chmod 777 /tmp/v2ray_update/v2ray
            chmod 777 /tmp/v2ray_update/v2ctl
            upx  --lzma --ultra-brute /tmp/v2ray_update/v2ray /tmp/v2ray_update/v2ctl
            #重新打包
            cd /tmp/v2ray_update
            zip /tmp/v2ray-linux-arm32-v5-upx.zip -r ./*
        else
            echo "请检查当前网络"
        fi
    else
        echo "版本一样，不需要更新"
    fi
else
    echo "请检查当前网络"
fi
