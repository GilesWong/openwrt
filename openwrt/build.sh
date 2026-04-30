#!/bin/bash -e
export RED_COLOR='\e[1;31m'
export GREEN_COLOR='\e[1;32m'
export YELLOW_COLOR='\e[1;33m'
export RES='\e[0m'

GROUP=
group() {
    endgroup
    echo "::group::  $1"
    GROUP=1
}
endgroup() {
    if [ -n "$GROUP" ]; then
        echo "::endgroup::"
    fi
    GROUP=
}

###############################
#  ImmortalWrt Build Script    #
###############################

# github proxy
[ "$CN_PROXY" = "y" ] && [ -z "$GITHUB_REPO" ] && github_proxy="git.apad.pro/https://" || github_proxy=""
export github="$github_proxy"github.com

# check root
if [ "$(id -u)" = "0" ]; then
    echo -e "${RED_COLOR}Building with root user is not supported.${RES}"
    exit 1
fi

# cpus
cores=$(expr $(nproc --all) + 1)

# fix for github workflows using env var
[ "$(whoami)" = "runner" ] && [ -n "$GITHUB_REPO" ] && OPENWRT_REPO=$GITHUB_REPO
export OPENWRT_REPO=${OPENWRT_REPO:-GilesWong/openwrt}
export mirror="$github_proxy"raw.githubusercontent.com/$OPENWRT_REPO/main

# $CURL_BAR
if curl --help | grep progress-bar >/dev/null 2>&1; then
    CURL_BAR="--progress-bar";
fi

if [ -z "$1" ] || [ "$2" != "x86_64" ]; then
    echo -e "\n${RED_COLOR}Building type not specified.${RES}\n"
    echo -e "Usage:\n"
    echo -e "${GREEN_COLOR}bash build.sh lite x86_64${RES}\n"
    exit 1
fi

# platform
[ "$2" = "x86_64" ] && export platform="x86_64"

# lan
[ -n "$LAN" ] && export LAN=$LAN || export LAN=10.0.0.1

# start time
starttime=$(date +'%Y-%m-%d %H:%M:%S')
CURRENT_DATE=$(date +%s)

echo -e "\r\n${GREEN_COLOR}Building ImmortalWrt 24.10${RES}\r\n"
echo -e "${GREEN_COLOR}Model: x86_64${RES}"
echo -e "${GREEN_COLOR}LAN: $LAN${RES}\r\n"

# clean old files
rm -rf openwrt

[ "$(whoami)" = "runner" ] && group "source code"
git clone --depth=1 --branch openwrt-24.10 https://$github/immortalwrt/immortalwrt openwrt
[ "$(whoami)" = "runner" ] && endgroup

if [ -d openwrt ]; then
    cd openwrt
    echo "$CURRENT_DATE" > version.date
else
    echo -e "${RED_COLOR}Failed to download source code${RES}"
    exit 1
fi

# append nikki feed to default feeds.conf
echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default

[ "$(whoami)" = "runner" ] && group "feeds update -a"
./scripts/feeds update -a
[ "$(whoami)" = "runner" ] && endgroup

[ "$(whoami)" = "runner" ] && group "feeds install -a"
./scripts/feeds install -a
[ "$(whoami)" = "runner" ] && endgroup

# loader dl
if [ -f ../dl.gz ]; then
    tar xf ../dl.gz -C .
fi

# set LAN IP
sed -i 's/192\.168\.1\.1/'"$LAN"'/g' package/base-files/files/bin/config_generate

###############################################
echo -e "\n${GREEN_COLOR}Setting up custom packages ...${RES}\n"

# download and run 06-custom.sh
curl -sO https://$mirror/openwrt/scripts/06-custom.sh
chmod 0755 06-custom.sh
[ "$(whoami)" = "runner" ] && group "patching openwrt"
bash 06-custom.sh
[ "$(whoami)" = "runner" ] && endgroup

rm -f 06-custom.sh

# assemble .config
echo -e "\n${GREEN_COLOR}Assembling .config ...${RES}\n"

# device config
curl -s https://$mirror/openwrt/23-config-musl-x86 >> .config

# base system config
curl -s https://$mirror/openwrt/23-config-common-base >> .config

# custom app config
curl -s https://$mirror/openwrt/23-config-common-custom >> .config

# LAN ports for x86_64
[ -n "$LAN_PORTS" ] && sed -i "s/lan.ports='4'/lan.ports='$LAN_PORTS'/g" package/base-files/files/bin/config_generate

# init openwrt config
rm -rf tmp/*
make defconfig

# compile
echo -e "\r\n${GREEN_COLOR}Building ImmortalWrt ...${RES}\r\n"
make -j$cores IGNORE_ERRORS="n m"

# compile time
endtime=$(date +'%Y-%m-%d %H:%M:%S')
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
SEC=$((end_seconds-start_seconds));

if [ -f bin/targets/x86/64/sha256sums ]; then
    echo -e "${GREEN_COLOR} Build success! ${RES}"
    echo -e " Build time: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s"
else
    echo -e "\n${RED_COLOR} Build error... ${RES}"
    echo -e " Build time: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s"
    echo
    exit 1
fi

# backup download cache
if [ "$CN_PROXY" = "y" ]; then
    rm -rf dl/geo* dl/go-mod-cache
    tar cf ../dl.gz dl
fi
exit 0
