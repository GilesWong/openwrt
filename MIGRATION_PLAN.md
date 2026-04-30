# Migration Plan: pmkol/openwrt-lite → ImmortalWrt 24.10

## 目标

从 `pmkol/openwrt-lite` (OpenWrt 23.05 + Linux 6.11) 完全迁移到 `immortalwrt/immortalwrt@openwrt-24.10` (Linux 6.6 LTS)，仅保留 x86_64 目标。

> 使用分支 `openwrt-24.10`（而非固定 tag `v24.10.6`），自动跟踪 ImmortalWrt 24.10 系列最新更新。

## 关键约束

- **仅 x86_64** — 不再支持 NanoPi R4S/R5S
- **保留 luci-app-nikki** — 从 `nikkinikki-org/OpenWrt-nikki` feed 引入
- **ImmortalWrt 默认内核** — 放弃 BBRv3 / LRNG / Shortcut-FE / TCP Brutal 等 pmkol 内核补丁
- **完全脱离 pmkol 仓库** — 所有 `github.com/pmkol/*` 引用清零

---

## 第一阶段：删除 pmkol 专属文件

### 整目录删除

| 路径 | 说明 |
|------|------|
| `openwrt/patch/` | 76+ pmkol 补丁（内核/包/LLVM/LuCI），不适用于 ImmortalWrt 24.10 |
| `openwrt/generic/` | pmkol 编译参数片段（config-gcc14/bpf/lto/firmware/upx_list.txt） |

### 单文件删除

| 路径 | 说明 |
|------|------|
| `build.sh` | 根目录废弃入口脚本 |
| `openwrt/build.sh` | 旧构建脚本，指向 pmkol 仓库 |
| `openwrt/scripts/00-prepare_base.sh` | pmkol 基础补丁（367 行） |
| `openwrt/scripts/01-prepare_base-mainline.sh` | pmkol 内核 6.11 模块/BBRv3/LRNG 补丁 |
| `openwrt/scripts/02-prepare_package.sh` | pmkol 包版本更新、opkg 源配置 |
| `openwrt/scripts/03-convert_translation.sh` | pmkol 翻译文件转换 |
| `openwrt/scripts/04-fix_kmod.sh` | pmkol 内核模块 6.11 修复 |
| `openwrt/scripts/05-fix-source.sh` | pmkol GCC14/Clang 源码修复 |
| `openwrt/scripts/99_clean_build_cache.sh` | pmkol 构建缓存清理 |
| `openwrt/23-config-common-lite` | pmkol Lite 基线配置 |
| `openwrt/23-config-common-server` | pmkol Server 基线配置 |
| `openwrt/23-config-musl-x86` | pmkol x86_64 设备配置 |
| `openwrt/23-config-musl-x86-dev` | pmkol x86_64 dev 设备配置 |
| `openwrt/23-config-musl-r4s` | pmkol NanoPi R4S 设备配置 |
| `openwrt/23-config-musl-r5s` | pmkol NanoPi R5S 设备配置 |
| `.github/workflows/build-openwrt-lite.yml` | pmkol Lite CI |
| `.github/workflows/build-openwrt-server.yml` | pmkol Server CI |
| `.github/workflows/build-openwrt-thin.yml` | pmkol Thin CI |
| `.github/workflows/build-openwrt-dev.yml` | pmkol Dev CI |
| `.github/workflows/build-toolchain-cache.yml` | pmkol 工具链缓存构建 |

---

## 第二阶段：重写 `openwrt/build.sh`

### 新脚本职责

1. 接收参数：`<version_type> <device>`（device 固定 x86_64）
2. 编译依赖安装（ImmortalWrt 官方列表）：
   ```bash
   sudo apt-get install -y build-essential flex bison cmake g++ gawk gcc-multilib g++-multilib \
     gettext git libfuse-dev libncurses5-dev libssl-dev python3 python3-pip python3-ply \
     python3-pyelftools rsync unzip zlib1g-dev file wget subversion patch upx-ucl autoconf \
     automake curl asciidoc binutils bzip2 lib32gcc-s1 libc6-dev-i386 uglifyjs msmtp texinfo \
     libreadline-dev libglib2.0-dev xmlto libelf-dev libtool autopoint antlr3 gperf ccache \
     swig coreutils haveged scons libpython3-dev rename qemu-utils jq lld llvm
   ```
3. 克隆源：
   ```bash
   # ImmortalWrt 24.10 的分支名是 openwrt-24.10（不是 v24.10.6 tag）
   git clone --depth=1 --branch openwrt-24.10 \
     https://github.com/immortalwrt/immortalwrt openwrt
   cd openwrt
   ```
4. 配置 feeds（**在默认 feeds.conf.default 基础上追加** nikki，不替换整个文件）：
   ```bash
   # 追加 nikki feed
   echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> feeds.conf.default
   ```
5. 执行 `./scripts/feeds update -a && ./scripts/feeds install -a`
6. 配置 LAN IP（默认为 10.0.0.1）：
   ```bash
   # ImmortalWrt 默认 192.168.1.1，如需改为 10.0.0.1：
   sed -i 's/192\.168\.1\.1/10.0.0.1/g' package/base-files/files/bin/config_generate
   ```
7. 下载并执行 `06-custom.sh`，执行后 `./scripts/feeds update -i` 刷新索引
8. 组装 `.config`：
   - 从你的 repo 下载 `23-config-musl-x86`（设备配置）
   - 下载 `23-config-common-base`（基础系统配置）
   - 下载 `23-config-common-custom`（APP 选择）
   - 追加内联编译选项
9. `make defconfig && make -j$(nproc+1)`

### 移除的 pmkol 特性

- ❌ `KERNEL_CLANG_LTO` / `ENABLE_LTO` / `ENABLE_LRNG` / `ENABLE_BPF` / `ENABLE_MOLD` / `ENABLE_DPDK`
- ❌ `OPENWRT_KEY` / `kmod-sign`
- ❌ `TOOLCHAIN_URL` / `BUILD_FAST` 工具链缓存
- ❌ `CLANG_LTO_THIN` 低内存构建路径
- ❌ `GITHUB_REPO == pmkol/openwrt-lite` 条件分支
- ❌ `OPENWRT_REPO` 变量
- ❌ `MINIMAL_BUILD` / `CONFIG_CUSTOM` 多版本切换

---

## 第三阶段：创建 `openwrt/23-config-musl-x86`

### ImmortalWrt x86_64 generic target 配置

```
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y
CONFIG_TARGET_IMAGES_GZIP=y
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_TARGET_ROOTFS_PARTSIZE=944

# All kmods (编译全部内核模块)
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSHARED=y

# 基础系统
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_bash-completion=y
CONFIG_PACKAGE_sudo=y
CONFIG_PACKAGE_vim-full=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_dmesg=y
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_taskset=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_zoneinfo-asia=y
CONFIG_PACKAGE_bind-dig=y

# Core utils
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-dircolors=y
CONFIG_PACKAGE_coreutils-ls=y

# ZLIB 优化
CONFIG_ZLIB_OPTIMIZE_SPEED=y

# 镜像优化
CONFIG_IMAGEOPT=y
CONFIG_VERSIONOPT=y
CONFIG_VERSION_FILENAMES=y

# NIC 驱动
CONFIG_PACKAGE_kmod-igb=y       # Intel 1GbE
CONFIG_PACKAGE_kmod-igc=y       # Intel 2.5GbE
CONFIG_PACKAGE_kmod-r8101=y     # Realtek 8169
CONFIG_PACKAGE_kmod-r8125=y     # Realtek 2.5GbE
CONFIG_PACKAGE_kmod-r8126=y     # Realtek 5GbE
CONFIG_PACKAGE_kmod-r8168=y     # Realtek 8168

# NVMe
CONFIG_PACKAGE_kmod-nvme=y
CONFIG_PACKAGE_kmod-nvme-core=y

# USB 3.0
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
```

> ⚠️ 初始化时可能需要 `make menuconfig` 来确认 `CONFIG_TARGET_x86_64_DEVICE_generic` 的实际名称

---

## 第四阶段：创建 `openwrt/23-config-common-base`

参照旧的 `23-config-common-lite` 1-145 行（"### APPS" 之前），映射到 ImmortalWrt 24.10 包名。ImmortalWrt 已集成大量常用补丁（Fullcone NAT、Shortcut-FE 等），部分 pmkol 独有的内核特性（BBRv3、LRNG、TCP Brutal）直接放弃。

### 完整基础配置

```
### Busybox
CONFIG_BUSYBOX_CUSTOM=y
CONFIG_BUSYBOX_CONFIG_ASH_HELP=y
CONFIG_BUSYBOX_CONFIG_FEATURE_EDITING_HISTORY=1024
CONFIG_BUSYBOX_CONFIG_FEATURE_EDITING_SAVEHISTORY=y
CONFIG_BUSYBOX_CONFIG_FEATURE_PREFER_IPV4_ADDRESS=y
CONFIG_BUSYBOX_CONFIG_FEATURE_SH_HISTFILESIZE=y
CONFIG_BUSYBOX_CONFIG_FEATURE_SYSLOG_INFO=y

### Firewall — nftables 专用，不启用 iptables legacy
CONFIG_PACKAGE_firewall4=y
# CONFIG_PACKAGE_ip6tables-nft is not set
# CONFIG_PACKAGE_iptables-legacy is not set

### Shortcut-FE — ImmortalWrt 标准内核模块
# 注意：ImmortalWrt 中名称可能为 kmod-sfe 或 kmod-fast-classifier，需 make menuconfig 确认
# 首次构建时建议先注释，待验证后再启用：
# CONFIG_PACKAGE_kmod-fast-classifier=y
# CONFIG_PACKAGE_kmod-shortcut-fe-cm=y

### Fullcone NAT — ImmortalWrt 已集成
CONFIG_PACKAGE_kmod-nft-fullcone=y

### Zram
CONFIG_PACKAGE_zram-swap=y

### Curl (HTTP3/QUIC)
# ImmortalWrt 用 libngtcp2 实现 QUIC，只需一个 CONFIG_LIBCURL_HTTP3 选项
# libnghttp3 + libngtcp2 作为依赖自动拉取，无需打 OpenSSL QUIC 补丁
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_libcurl=y
CONFIG_LIBCURL_HTTP3=y
CONFIG_LIBCURL_OPENSSL=y

### Dnsmasq
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dnsmasq_full_ipset=y
# CONFIG_PACKAGE_dnsmasq is not set

### LuCI 基础包
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci=y
# CONFIG_PACKAGE_luci-ssl is not set
CONFIG_PACKAGE_luci-lib-base=y
CONFIG_PACKAGE_luci-lib-ip=y
CONFIG_PACKAGE_luci-lib-jsonc=y
CONFIG_PACKAGE_luci-lib-nixio=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_LUCI_LANG_zh_Hans=y

### OpenSSL — 速度优先
CONFIG_OPENSSL_ENGINE=y
CONFIG_OPENSSL_OPTIMIZE_SPEED=y
CONFIG_OPENSSL_WITH_ASM=y
CONFIG_PACKAGE_libopenssl-conf=y
CONFIG_PACKAGE_libopenssl-legacy=y
CONFIG_PACKAGE_openssl-util=y

### 内核模块
CONFIG_PACKAGE_kmod-br-netfilter=y
CONFIG_PACKAGE_kmod-button-hotplug=y
CONFIG_PACKAGE_kmod-crypto-chacha20poly1305=y
CONFIG_PACKAGE_kmod-crypto-sha256=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_kmod-fs-ntfs3=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-xfs=y
# CONFIG_PACKAGE_kmod-hwmon-pwmfan is not set
CONFIG_PACKAGE_kmod-ikconfig=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-iptunnel6=y
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_kmod-nf-socket=y
CONFIG_PACKAGE_kmod-nft-offload=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-sched=y
CONFIG_PACKAGE_kmod-tls=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_kmod-usb-audio=y
CONFIG_PACKAGE_kmod-usb-hid=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152-vendor=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-usb2-pci=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y

# 以下 pmkol 独有的内核模块在 ImmortalWrt 中不存在，直接移除：
# CONFIG_PACKAGE_kmod-tcp-bbr3 — 不存在，用默认 BBRv1
# CONFIG_PACKAGE_kmod-tcp-brutal — 不存在
# CONFIG_PACKAGE_kmod-fast-classifier / kmod-shortcut-fe-cm — 需验证名称后启用

### 系统工具
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_bash-completion=y
CONFIG_PACKAGE_bind-dig=y
CONFIG_PACKAGE_dmesg=y
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_sudo=y
CONFIG_PACKAGE_taskset=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_vim=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_wpad-openssl=y
CONFIG_PACKAGE_zoneinfo-asia=y

### GNU Core Utilities
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-dircolors=y
CONFIG_PACKAGE_coreutils-ls=y

### 镜像 & 版本选项
CONFIG_IMAGEOPT=y
CONFIG_VERSIONOPT=y
CONFIG_VERSION_FILENAMES=y

### ZLIB — 速度优先
CONFIG_ZLIB_OPTIMIZE_SPEED=y
```

### 需要 make menuconfig 验证的项

| 原 pmkol 包名 | ImmortalWrt 24.10 中的可能名称 | 操作 |
|---------------|-------------------------------|------|
| `CONFIG_PACKAGE_kmod-fast-classifier` | 可能是 `CONFIG_PACKAGE_kmod-sfe` | `make menuconfig` 搜索确认 |
| `CONFIG_PACKAGE_kmod-shortcut-fe-cm` | 同上 | 同上 |
| `CONFIG_PACKAGE_nat6` | ImmortalWrt 可能已内置 | 验证后决定是否保留 |
| `CONFIG_PACKAGE_luci-lib-ipkg` | OpenWrt 24.10 可能改名 | 验证后添加 |
| `CONFIG_PACKAGE_procd-ujail` | ImmortalWrt 可能默认启用 | 验证 |
| `CONFIG_PACKAGE_libopenssl-afalg` | Linux AF_ALG 引擎 | 仅 x86_64 可用，验证 |
| `CONFIG_PACKAGE_libopenssl-devcrypto` | /dev/crypto 引擎 | 验证是否需显式启用 |

> **原则**：首次 `make defconfig` 后会报告缺失的 CONFIG 项，可根据报错逐项修正。

---

## 第五阶段：修改 `openwrt/23-config-common-custom`

### 包名兼容性对照

#### ✅ 直接兼容（ImmortalWrt 24.10 内置）

直接保留，命名完全相同：

```
CONFIG_PACKAGE_luci-app-cpufreq=y
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-frpc=y
CONFIG_PACKAGE_luci-app-hd-idle=y
CONFIG_PACKAGE_luci-app-netdata=y
CONFIG_PACKAGE_luci-app-nlbwmon=y
CONFIG_PACKAGE_luci-app-ramfree=y
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-vlmcsd=y
CONFIG_PACKAGE_luci-app-watchcat=y
CONFIG_PACKAGE_luci-app-ddns-go=y
```

#### 🔧 需要从第三方源拉取（后端在 ImmortalWrt，缺 LuCI）

> 已验证：`sbwml/luci-app-tailscale`、`sbwml/luci-app-socat`、`sbwml/luci-app-eqosplus`、`sbwml/luci-app-wolplus` **均不存在 (404)**，以下为实际可用替代源。

| 包名 | 来源 | 状态 | 说明 |
|------|------|------|------|
| `luci-app-mosdns` | `sbwml/luci-app-mosdns` | ✅ v5.3.4-r3 (2026-04) | ⚠️ 多包仓库，需完整 clone + golang 1.24+ |
| `luci-app-tailscale`→`luci-app-tailscale-ng` | `vad-b/luci-app-tailscale-ng` | ✅ v2026-02 | 单包仓库，直接 clone |
| `luci-app-socat` | — | ❌ 暂不集成 | 由用户决定后续是否需要 |
| `luci-app-eqosplus` | `sirpdboy/luci-app-eqosplus` | ✅ v1.3.0 (2025-12) | 单包仓库，直接 clone |
| `luci-app-netspeedtest` | `sirpdboy/netspeedtest` | ✅ v5.2.1 (2026-03) | ⚠️ 多包仓库，需提取 `luci-app-netspeedtest/` 子目录 |
| `luci-app-wolplus` | ~~animegasan~~ → **用内置** | ❌→✅ | 改换 ImmortalWrt 内置 `luci-app-wol` |

集成方式：在 `06-custom.sh` 中 `git clone` 到 `package/new/`

#### ❗ 通过 Feed 引入

| 包名 | 来源 |
|------|------|
| `luci-app-nikki` | `nikkinikki-org/OpenWrt-nikki` feed（已在 feeds.conf.default 中追加） |

> ⚠️ nikki 额外依赖验证：
> - `yq` — 命令行 YAML 处理工具，nikki 必需。需确认 ImmortalWrt 24.10 的 packages feed 中是否存在
> - `ip-full` — nikki 要求，ImmortalWrt 标准包，确认存在
> - `kmod-dummy`、`kmod-inet-diag`、`kmod-nft-socket`、`kmod-nft-tproxy`、`kmod-tun` — 已在 base config 中配置
> - `ca-bundle`、`curl`、`firewall4` — ImmortalWrt 标准包
>
> ⚠️ ImmortalWrt 24.10 / OpenWrt 24.10 已开始切换包管理器从 `opkg` 到 `apk`：
> - feeds 中部分包的安装方式可能有变化
> - 内核模块包（`kmod-*`）的 `apk` vs `opkg` 命名规则可能需要适配
> - 预编译 `.ipk` 文件（如 natfrp）在 apk 系统上需要验证兼容性

### 移除的块

```
移除：
  ### DDNS Scripts      — 全部已在当前配置设为 not set
  ### Dae               — 不在 ImmortalWrt
  ### L2TP              — 不在 ImmortalWrt
  ### Passwall          — 可选：disable 块保留还是删除
  ### Singbox           — lucI-app-momo 不存在于 ImmortalWrt
  ### Wireguard         — 作为内核模块已不需要在 APP 中单独开关
```

### 新增块

```
### Nikki
CONFIG_PACKAGE_luci-app-nikki=y

### 新增（从第三方源拉取的包在 06-custom.sh 中处理）
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-tailscale-ng=y      # 注意包名：tailscale → tailscale-ng
CONFIG_PACKAGE_luci-app-eqosplus=y
CONFIG_PACKAGE_luci-app-netspeedtest=y
CONFIG_PACKAGE_luci-app-wol=y               # 用 ImmortalWrt 内置 wol 代替 wolplus
CONFIG_PACKAGE_luci-app-natfrp=y            # 从源编译（见第六阶段 natfrp 改造）
```

---

## 第六阶段：修改 `openwrt/scripts/06-custom.sh`

### 保留的内容

```bash
#!/bin/bash -e

# lrzsz - add patched package (single-package repo, root IS package)
rm -rf feeds/packages/utils/lrzsz
git clone --depth=1 https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz
```

### 需要移除的内容

```bash
# vlmcsd — ImmortalWrt 24.10 已内置 luci-app-vlmcsd 和 vlmcsd 后端
# 第 15-16 行删除
```

### 新增：缺失 LuCI 包的第三方源

> ⚠️ 部分第三方仓库是**多包仓库**。`luci-app-mosdns` 需要**整个仓库**而非只提取 LuCI 子目录，因为 mosdns 后端需要配套的 v5 版本二进制。`netspeedtest` 只需提取 `luci-app-netspeedtest/` 子目录。

```bash
# mosdns v5 — 需要完整仓库（luci + mosdns 后端 + v2dat）+ golang 1.24+
# 先删除 ImmortalWrt 自带的旧版 mosdns / v2ray-geodata
rm -rf package/feeds/packages/mosdns
rm -rf package/feeds/packages/net/v2ray-geodata

# 更新 golang 到 1.24.x（mosdns v5 必需）
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# clone 完整 mosdns 仓库（luci-app-mosdns + mosdns 后端 + v2dat）
git clone --depth=1 https://$github/sbwml/luci-app-mosdns -b v5 package/mosdns

# clone v2ray-geodata（geoip/geosite 规则数据）
git clone --depth=1 https://$github/sbwml/v2ray-geodata package/v2ray-geodata

# tailscale-ng LuCI（单包仓库，root 即为包）
git clone --depth=1 https://$github/vad-b/luci-app-tailscale-ng package/new/luci-app-tailscale-ng

# eqosplus LuCI（单包仓库）
git clone --depth=1 https://$github/sirpdboy/luci-app-eqosplus package/new/luci-app-eqosplus

# netspeedtest LuCI — 多包仓库，提取 luci-app-netspeedtest 子目录
# (homebox/ 与 ookla-speedtest/ 子目录不需要)
git clone --depth=1 https://$github/sirpdboy/netspeedtest /tmp/netspeedtest

cp -r /tmp/netspeedtest/luci-app-netspeedtest package/new/luci-app-netspeedtest
rm -rf /tmp/netspeedtest
# remove unneeded dependencies (homebox & ookla-speedtest are not in build scope)
sed -i '/+ookla-speedtest/d; /+homebox/d' package/new/luci-app-netspeedtest/Makefile

# socat — 暂不集成
```

### natfrp — 改造为从源编译

**现状**：旧的 06-custom.sh 下载预编译 IPK，注入 rootfs，首次启动安装。

**`natfrp/luci-app-natfrp` 仓库分析**：
- 实验性项目，未采用 OpenWrt 官方构建系统，不涉及编译，纯打包
- README 提供了 Makefile 模板，二进文件从 `https://nya.globalslb.net/natfrp/client/launcher-openwrt/` CDN 获取
- 依赖：`+luci-compat`（ImmortalWrt 可用）
- `binary/` 目录含架构相关二进制，`data/` 含 LuCI 文件，`control/` 含包控制文件

**方案：克隆仓库 + 补充 Makefile 中二进制下载逻辑**

```bash
# natfrp — 克隆仓库作为 OpenWrt 包源
git clone --depth=1 https://github.com/natfrp/luci-app-natfrp package/new/luci-app-natfrp

# 从 CDN 下载 x86_64 二进制并放入 package 目录
mkdir -p package/new/luci-app-natfrp/binary
natfrp_ver=$(curl -s https://nya.globalslb.net/natfrp/client/launcher-openwrt/ \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(?=/)' | sort -V | tail -n 1)
natfrp_ver=${natfrp_ver:-"3.1.7"}
curl -Lso package/new/luci-app-natfrp/binary/natfrp_amd64 \
  "https://nya.globalslb.net/natfrp/client/launcher-openwrt/$natfrp_ver/natfrp_amd64"
chmod 755 package/new/luci-app-natfrp/binary/natfrp_amd64
```

**注意**：
- 该仓库使用自定义构建脚本 `build.sh` 打包 IPK，不是标准 OpenWrt Makefile
- 克隆到 `package/new/` 后，`make` 可能无法自动识别。需要验证仓库中是否有 `Makefile`，或者需要编写一个桥接 Makefile
- 或者保留预编译 IPK 方案（`files/natfrp/` + `files/etc/init.d/natfrp-install`），这是 natfrp 官方推荐的方式
- ⚠️ ImmortalWrt 24.10 使用 `apk` 包管理器，预编译 `.ipk` 文件可能需要 `opkg` 作为兼容层，或需要 `.apk` 格式

---

## 第七阶段：修改 CI Workflow

### 改造 `.github/workflows/build-openwrt-23.05.yml`

关键变更：
1. workflow name → `Build ImmortalWrt 24.10 Custom`
2. 去掉 `device` 选项（仅 `x86_64` 硬编码）
3. 构建依赖改用 ImmortalWrt 推荐列表（见第二阶段）
4. 构建命令改为新的 `build.sh` 路径
5. **产物路径**：ImmortalWrt x86_64 输出在 `openwrt/bin/targets/x86/64/`（注意子目录 `64/` 而非旧的 `x86/*/`）
   ```
   # 产物收集示例
   cp -a openwrt/bin/targets/x86/64/*-ext4-combined.img.gz rom/
   cp -a openwrt/bin/targets/x86/64/*-squashfs-combined.img.gz rom/
   cp -a openwrt/bin/targets/x86/64/*-ext4-combined-efi.img.gz rom/
   cp -a openwrt/bin/targets/x86/64/*-squashfs-combined-efi.img.gz rom/
   cp -a openwrt/bin/targets/x86/64/*-generic-rootfs.tar.gz rom/
   ```

---

## 第八阶段：files/ 目录调整

| 路径 | 操作 |
|------|------|
| `openwrt/files/root/.bash_profile` | 保留 |
| `openwrt/files/root/.bashrc` | 保留 |
| `openwrt/files/etc/sysctl.d/15-vm-swappiness.conf` | 保留 |
| `openwrt/files/etc/sysctl.d/16-udp-buffer-size.conf` | 保留 |
| `openwrt/files/etc/hotplug.d/iface/90-tailscale` | **删除** — 旧 luci-app-tailscale 的热插拔脚本，改用 `luci-app-tailscale-ng` 后不兼容（tailscale-ng 自带 hotplug 机制） |
| `openwrt/files/etc/init.d/natfrp-install` | 取决于 natfrp 方案：若改用从源编译则删除；若保留预编译 IPK 注入则保留 |
| `openwrt/files/sbin/emmc-install` | **删除**（仅 x86_64，不再需要 eMMC） |

---

## 迁移后文件结构

```
openwrt/
├── build.sh                     ← 重写：ImmortalWrt 24.10 x86_64 构建
├── 23-config-musl-x86           ← 新文件：x86_64 设备配置
├── 23-config-common-base        ← 新文件：基础系统配置（含 LuCI/内核/工具）
├── 23-config-common-custom      ← 修改：APP 选择（去 pmkol 化 + 新增 nikki/natfrp）
├── scripts/
│   └── 06-custom.sh             ← 修改：保留 lrzsz，新增 mosdns/tailscale-ng/eqosplus/netspeedtest + natfrp
├── files/
│   ├── root/                    ← 保留 .bash_profile, .bashrc
│   └── etc/                     ← 保留 sysctl.d, 删除 emmc-install, 删除旧 tailscale hotplug
└── README.md                     ← 修改：更新为 ImmortalWrt 项目说明

.github/workflows/
└── build-immortalwrt-custom.yml ← 修改：适配 ImmortalWrt 24.10
```

---

## 第九阶段：更新 README.md

当前 README.md 严重依赖 pmkol 品牌和信息，需全面更新：

### 需要删除/替换的内容

| 行号范围 | 内容 | 操作 |
|----------|------|------|
| 11 | `https://github.com/pmkol/openwrt-lite/releases` | 改为你的 fork releases 地址 |
| 8 | `Infinity Nikki` Telegram 群 | 删除或改为你的联系方式 |
| 4 | 项目描述提到"自动构建的扩展软件源" | 改为 ImmortalWrt 描述 |
| 34-54 | "固件说明"中内核 6.11.11、Shortcut-FE | 改为 ImmortalWrt 属性 |
| 58-92 | "版本说明"中 Lite/Thin/Server | 改为你的版本说明（仅 x86_64） |
| 149-155 | "自定义构建固件"中 Clang19/GCC14 | 改为 ImmortalWrt 默认工具链 |
| 197-202 | 替换 `pmkol/openwrt-lite` → 你的用户名/仓库名 | 保留 fork 教程 |
| 216-240 | 构建脚本地址改为 `immortalwrt/immortalwrt` | 更新 clone 命令 |
| 244-320 | 高级构建参数中 pmkol 独有的参数 | 移除或调整 |

### 新增内容

- ImmortalWrt 默认登录地址 `192.168.1.1`（或你的 `10.0.0.1`）
- ImmortalWrt 24.10 基础信息（内核 6.6 LTS）
- 自定义包列表说明（nikki、mosdns、tailscale-ng 等）
- CI 构建说明（仅 x86_64）

---

## 需验证清单

### 必须在实施前验证 (Blockers)
- [ ] ImmortalWrt 分支名：确认 `openwrt-24.10` 是当前维护分支（非 tag `v24.10.6`）
- [ ] `feeds.conf.default` 默认内容：确认 ImmortalWrt 自带 feeds 指向正确
- [ ] `yq` 包：确认 ImmortalWrt 24.10 feeds 中是否包含（nikki 硬依赖，缺失则编译失败）
- [ ] `apk` vs `opkg`：确认 ImmortalWrt 24.10 的包管理器模式，及对 `kmod-*` 命名的影响
- [ ] Shortcut-FE 包名：`make menuconfig` 搜索 `CONFIG_PACKAGE_kmod-fast-classifier` 或 `kmod-sfe` 确认

- [x] `kmod-hwmon-pwmfan` → 已注释（ImmortalWrt 6.6 内核中依赖不兼容）
- [x] `libustream-mbedtls` 冲突 → 改用 `CONFIG_PACKAGE_luci`（不用 `luci-ssl`），避免硬编码 mbedtls 依赖

### 构建运行中验证
- [ ] `CONFIG_TARGET_x86_64_DEVICE_generic` 实际名称（`make defconfig` 报错时可修正）
- [ ] `luci-lib-ipkg` → 可能在 OpenWrt 24.10 改名，检查 `make defconfig` 报错
- [ ] `CONFIG_PACKAGE_nat6` — ImmortalWrt 可能不需要显式启用
- [ ] `CONFIG_PACKAGE_libopenssl-afalg`、`CONFIG_PACKAGE_libopenssl-devcrypto` — 验证是否需要
- [ ] Base config 中所有 `CONFIG_PACKAGE_kmod-*` 名称在 ImmortalWrt 中是否变化
- [ ] 首次 `make menuconfig` 验证：保存后检查缺失项报告

### 第三方仓库状态（已验证 ✅）
- [x] `sbwml/luci-app-mosdns` (v5) — 可用
- [x] `vad-b/luci-app-tailscale-ng` — 可用（luci-app-tailscale → luci-app-tailscale-ng）
- [x] `sirpdboy/luci-app-eqosplus` — 可用
- [x] `sirpdboy/netspeedtest` — 可用
- [x] `nikkinikki-org/OpenWrt-nikki` — feed 可用（`;main` 分支）
- [x] `luci-app-wolplus` → 改为内置 `luci-app-wol`
- [x] `luci-app-socat` → 暂不集成
- [x] `luci-app-vlmcsd` → 无需在 06-custom.sh 中拉取（ImmortalWrt 已内置，custom config 中 Enable 即可）

### 待决策
- [ ] `natfrp` 方案：从源编译 (git clone repo) vs 预编译 IPK 注入 (files/natfrp/ + init.d)
