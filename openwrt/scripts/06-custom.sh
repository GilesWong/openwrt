#!/bin/bash -e

### Add new packages or patches below

# openlist - add new package
git clone https://$github/sbwml/luci-app-openlist2 package/new/openlist

# lrzsz - add patched package
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# mosdns LuCI (mosdns backend is in ImmortalWrt packages)
git clone https://$github/sbwml/luci-app-mosdns -b v5 package/new/mosdns

# tailscale-ng LuCI (tailscale backend is in ImmortalWrt packages)
git clone https://$github/vad-b/luci-app-tailscale-ng package/new/luci-app-tailscale-ng

# eqosplus LuCI
git clone https://$github/sirpdboy/luci-app-eqosplus package/new/luci-app-eqosplus

# netspeedtest LuCI
git clone https://$github/sirpdboy/netspeedtest package/new/netspeedtest

# natfrp - prebuilt IPK injection (official recommendation)
mkdir -p files/natfrp
if [ "$platform" = "x86_64" ]; then
    natfrp_arch="amd64"
else
    natfrp_arch="amd64"
fi
natfrp_ver=$(curl -s https://nya.globalslb.net/natfrp/client/launcher-openwrt/ | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(?=/)' | sort -V | tail -n 1)
natfrp_ver=${natfrp_ver:-"3.1.7"}
curl -Lso files/natfrp/luci-app-natfrp.ipk "https://nya.globalslb.net/natfrp/client/launcher-openwrt/$natfrp_ver/luci-app-natfrp_${natfrp_arch}.ipk"
mkdir -p files/etc/init.d
curl -so files/etc/init.d/natfrp-install https://$mirror/openwrt/files/etc/init.d/natfrp-install
chmod 755 files/etc/init.d/natfrp-install
