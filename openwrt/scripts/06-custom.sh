#!/bin/bash -e

### Add new packages or patches below
### For example, download openlist from a third-party repository to package/new/openlist
### Then, add CONFIG_PACKAGE_luci-app-openlist2=y to the end of openwrt/23-config-common-custom

# openlist - add new package
git clone https://$github/sbwml/luci-app-openlist2 package/new/openlist

# lrzsz - add patched package
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# vlmcsd - add new package
git clone https://$github/mchome/openwrt-vlmcsd package/new/vlmcsd
git clone https://$github/mchome/luci-app-vlmcsd package/new/luci-app-vlmcsd

# natfrp - download prebuilt ipk, inject into rootfs for first-boot install
mkdir -p files/natfrp
if [ "$platform" = "x86_64" ]; then
    natfrp_arch="amd64"
elif [ "$platform" = "rk3568" ]; then
    natfrp_arch="arm64"
elif [ "$platform" = "rk3399" ]; then
    natfrp_arch="armv7"
fi
natfrp_ver=$(curl -s https://nya.globalslb.net/natfrp/client/launcher-openwrt/ | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(?=/)' | sort -V | tail -n 1)
natfrp_ver=${natfrp_ver:-"3.1.7"}
curl -Lso files/natfrp/luci-app-natfrp.ipk "https://nya.globalslb.net/natfrp/client/launcher-openwrt/$natfrp_ver/luci-app-natfrp_${natfrp_arch}.ipk"
mkdir -p files/etc/init.d
curl -so files/etc/init.d/natfrp-install https://$mirror/openwrt/files/etc/init.d/natfrp-install
chmod 755 files/etc/init.d/natfrp-install
