# ImmortalWrt 24.10 Custom Build

### 基于 ImmortalWrt 24.10 定制的固件，x86_64 目标

基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) (OpenWrt 24.10 fork, Linux 6.6 LTS) 构建。

#### 固件下载：
https://github.com/GilesWong/openwrt/releases

#### 支持硬件：
- [x] X86_64

```
【首次登陆】
地址：10.0.0.1
用户：root
密码：空

【分区挂载】
系统 -> 磁盘管理 将系统盘剩余空间创建新分区
系统 -> 挂载点   启用新分区并挂载至/opt目录
```

---

### 固件说明：
- ImmortalWrt 24.10 + Linux Kernel 6.6 LTS
- 预装插件：
  - Nikki (Mihomo)
  - MosDNS
  - Tailscale-ng
  - DDNS-Go
  - EqosPlus
  - Frpc
  - Netdata
  - Samba4
  - UPnP
  - TTYD
  - Watchcat
  - 及更多...

---

### 自定义构建固件：

#### 使用 Github Actions 云构建（推荐）

#### 一、Fork 本仓库到自己 GitHub 存储库

#### 二、配置插件

- 修改 `openwrt/23-config-common-custom` 配置，注释或删除掉不需要的插件

- 按照 .config 格式添加需要的插件，例如 `CONFIG_PACKAGE_luci-app-mihomo=y`

- 如果添加了 Feed 中不存在的插件，请在 `openwrt/scripts/06-custom.sh` 加入插件引用代码

#### 三、构建固件

- 在存储库名称下，单击 Actions
- 在左侧边栏中，单击 "Build ImmortalWrt 24.10 Custom"
- 单击 "Run workflow" 按钮

---

#### 本地编译构建（内存16G+ / 硬盘80G+）

#### Linux 环境安装（debian 12+ / ubuntu 24+）
```shell
sudo apt-get update
sudo apt-get install -y build-essential flex bison cmake g++ gawk gcc-multilib g++-multilib gettext git libfuse-dev libncurses5-dev libssl-dev python3 python3-pip python3-ply python3-pyelftools rsync unzip zlib1g-dev file wget subversion patch upx-ucl autoconf automake curl asciidoc binutils bzip2 lib32gcc-s1 libc6-dev-i386 uglifyjs msmtp texinfo libreadline-dev libglib2.0-dev xmlto libelf-dev libtool autopoint antlr3 gperf ccache swig coreutils haveged scons libpython3-dev rename qemu-utils jq lld llvm
```

#### 一、Fork 本仓库

#### 二、修改构建脚本：`openwrt/build.sh`
将脚本默认 `OPENWRT_REPO` 替换为 `你的用户名/仓库名`

#### 三、配置插件
- 修改 `openwrt/23-config-common-custom`
- 如需自定义包在 `openwrt/scripts/06-custom.sh` 中添加

#### 四、执行构建
```shell
bash <(curl -sS https://raw.githubusercontent.com/你的用户名/仓库名/main/openwrt/build.sh) lite x86_64
```

---

#### 高级构建参数

#### 更改 LAN IP 地址
```
export LAN=10.0.0.1
```

#### 启用 GitHub 代理（仅限本地编译）
```
export CN_PROXY=y
```

---

### 特别致谢：
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [Nikki](https://github.com/nikkinikki-org/OpenWrt-nikki)
