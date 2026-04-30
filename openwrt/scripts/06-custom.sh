#!/bin/bash -e

### Add new packages or patches below

# lrzsz - add patched package (single-package repo, root IS package)
rm -rf feeds/packages/utils/lrzsz
git clone --depth=1 https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# mosdns v5 — requires golang 1.24+, full repo (not just luci subdir)
# remove ImmortalWrt's built-in mosdns and v2ray-geodata to avoid conflicts
rm -rf package/feeds/packages/mosdns
rm -rf package/feeds/packages/net/v2ray-geodata

# update golang to 1.24.x (required by mosdns v5)
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# clone full mosdns repo (luci + backend + v2dat)
git clone --depth=1 https://$github/sbwml/luci-app-mosdns -b v5 package/mosdns

# clone v2ray-geodata (geoip/geosite data for routing rules)
git clone --depth=1 https://$github/sbwml/v2ray-geodata package/v2ray-geodata

# tailscale-ng LuCI (single-package repo)
git clone --depth=1 https://$github/vad-b/luci-app-tailscale-ng package/new/luci-app-tailscale-ng

# eqosplus LuCI (single-package repo)
git clone --depth=1 https://$github/sirpdboy/luci-app-eqosplus package/new/luci-app-eqosplus

# netspeedtest LuCI - multi-package repo, extract only luci-app-netspeedtest
# (homebox & ookla-speedtest subdirs are not needed)
git clone --depth=1 https://$github/sirpdboy/netspeedtest /tmp/netspeedtest
cp -r /tmp/netspeedtest/luci-app-netspeedtest package/new/luci-app-netspeedtest
rm -rf /tmp/netspeedtest
# remove unneeded dependencies (homebox & ookla-speedtest are not in build scope)
sed -i '/+ookla-speedtest/d; /+homebox/d' package/new/luci-app-netspeedtest/Makefile

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
