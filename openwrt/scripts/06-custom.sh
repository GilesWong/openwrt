#!/bin/bash -e

### Add new packages or patches below

# openlist - multi-package repo, extract only luci-app-openlist2
git clone --depth=1 https://$github/sbwml/luci-app-openlist2 /tmp/luci-app-openlist2
cp -r /tmp/luci-app-openlist2/luci-app-openlist2 package/new/luci-app-openlist2
rm -rf /tmp/luci-app-openlist2

# lrzsz - add patched package (single-package repo, root IS package)
rm -rf feeds/packages/utils/lrzsz
git clone --depth=1 https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# mosdns LuCI - multi-package repo, extract only luci-app-mosdns
# (mosdns & v2dat subdirs would fail without golang toolchain)
git clone --depth=1 https://$github/sbwml/luci-app-mosdns -b v5 /tmp/luci-app-mosdns
cp -r /tmp/luci-app-mosdns/luci-app-mosdns package/new/luci-app-mosdns
rm -rf /tmp/luci-app-mosdns

# tailscale-ng LuCI (single-package repo)
git clone --depth=1 https://$github/vad-b/luci-app-tailscale-ng package/new/luci-app-tailscale-ng

# eqosplus LuCI (single-package repo)
git clone --depth=1 https://$github/sirpdboy/luci-app-eqosplus package/new/luci-app-eqosplus

# netspeedtest LuCI - multi-package repo, extract only luci-app-netspeedtest
# (homebox & ookla-speedtest subdirs are not needed)
git clone --depth=1 https://$github/sirpdboy/netspeedtest /tmp/netspeedtest
cp -r /tmp/netspeedtest/luci-app-netspeedtest package/new/luci-app-netspeedtest
rm -rf /tmp/netspeedtest

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
