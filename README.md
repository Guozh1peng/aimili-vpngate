# AimiliVPN

AimiliVPN 是一个基于 VPNGate 公共节点的 OpenVPN 代理网关管理器。项目使用 Python 标准库实现 Web 管理后台、节点拉取与测速、OpenVPN 连接管理、HTTP/SOCKS5 代理网关、多出口实例维护和运行日志。

当前仓库主要面向 Linux VPS 部署，默认安装目录为 `/opt/aimilivpn`，默认 Web 管理端口为 `8787`，默认代理端口为 `7928`。

## 目录

- [功能概览](#功能概览)
- [项目文件](#项目文件)
- [系统要求](#系统要求)
- [安装](#安装)
- [管理命令](#管理命令)
- [Web 管理后台](#web-管理后台)
- [代理使用](#代理使用)
- [配置与数据路径](#配置与数据路径)
- [运行机制](#运行机制)
- [日志](#日志)
- [卸载](#卸载)
- [常见问题](#常见问题)
- [English Quick Start](#english-quick-start)
- [许可证](#许可证)

## 功能概览

- 自动从 VPNGate API 拉取候选节点。
- 并发测试节点连通性和延迟，维护可用节点池。
- 通过 OpenVPN 建立主出口连接。
- 内置 HTTP/SOCKS5 双协议代理网关。
- 支持 Web 管理后台登录、节点连接、断开、切换和批量测试。
- 支持主出口锁定规则：自动配置、固定 IP、固定地区、多节点模式。
- 支持多出口代理实例，每个实例使用独立代理端口和独立 TUN 设备。
- 支持多出口实例锁定国家和 IP 类型，后台每 30 秒检测并自动更换失效实例。
- 支持网关状态自检、后台线程心跳、出口 IP 检测和代理端口测试。
- 支持今日运行日志查看、筛选、复制和导出。
- 安装脚本会生成 `ml` 命令，用于服务启停、状态查看、日志查看、更新、端口和账号密码配置。

## 项目文件

| 文件 | 说明 |
| --- | --- |
| `vpngate_manager.py` | 主程序。包含 Web UI、API、节点管理、OpenVPN 管理、多出口管理和日志系统。 |
| `proxy_server.py` | HTTP/SOCKS5 代理服务器。代理出站连接会绑定到指定 TUN 设备。 |
| `vpn_utils.py` | VPNGate 节点解析、延迟检测、IP 信息补全、DNS/网络诊断和故障原因识别工具。 |
| `install.sh` | 一键安装脚本。安装依赖、部署代码、创建系统服务和 `ml` 管理命令。 |
| `uninstall.sh` | 一键卸载脚本。停止服务并删除安装目录、系统服务和 `ml` 命令。 |
| `LICENSE` | GPL 许可证文本。 |

## 系统要求

推荐使用干净的 Linux VPS，并使用 `root` 权限部署。

支持的发行版：

- Debian / Ubuntu
- Alpine
- CentOS / RHEL / Rocky Linux / AlmaLinux / Fedora

运行依赖：

- Python 3
- OpenVPN
- curl
- git
- iproute2 或 iproute
- iptables
- psmisc
- ca-certificates

系统能力要求：

- VPS 必须启用 TUN/TAP。
- 服务需要 root 权限，代理出站连接需要绑定 TUN 设备。
- 云服务商安全组和系统防火墙需要放行 Web 管理端口和代理端口。

## 安装

在 Linux VPS 上以 root 用户执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Guozh1peng/aimili-vpngate/bate/install.sh)
```

如果你需要从 `main` 分支拉取安装脚本：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Guozh1peng/aimili-vpngate/main/install.sh)
```

注意：当前安装脚本的默认部署分支是 `bate`。如果 `/opt/aimilivpn` 已存在 Git 仓库，安装脚本会优先沿用当前已检出的分支。

安装脚本会执行以下操作：

- 安装系统依赖。
- 克隆或更新仓库到 `/opt/aimilivpn`。
- 创建 `aimilivpn.service` systemd 服务，或 OpenRC 服务。
- 创建 `/usr/bin/ml` 管理命令。
- 首次安装时生成 Web 登录账号、密码和安全后缀。
- 优化 `rp_filter=2`，减少策略路由回包被内核丢弃的问题。
- 启动服务并等待首次节点拉取和测速。

安装完成后终端会输出 Web 控制面板地址、账号和密码。

## 管理命令

安装后可以使用 `ml`：

```bash
ml
```

常用命令：

```bash
ml status
ml logs
ml start
ml stop
ml restart
ml update
ml web
ml port
ml password
ml uninstall
```

命令说明：

| 命令 | 说明 |
| --- | --- |
| `ml` | 打开交互式管理菜单。 |
| `ml status` | 查看服务、网关、OpenVPN、活动节点和多出口实例状态。 |
| `ml logs` | 查看实时运行日志。 |
| `ml start` | 启动 AimiliVPN 服务。 |
| `ml stop` | 停止 AimiliVPN 服务。 |
| `ml restart` | 重启 AimiliVPN 服务。 |
| `ml update` | 更新 `/opt/aimilivpn` 源码并重启服务。 |
| `ml web` | 修改 Web 管理地址、端口或安全后缀。 |
| `ml port` | 修改管理端口或代理端口配置。 |
| `ml password` | 修改或随机重置 Web 登录账号密码。 |
| `ml uninstall` | 完全卸载。 |

## Web 管理后台

Web 后台默认地址格式：

```text
http://服务器IP:8787/安全后缀/
```

核心页面能力：

- 查看候选节点池、目标可用数和活动连接数。
- 按国家筛选节点，按关键词搜索国家、位置、IP、ASN、运营商。
- 单节点检测、批量检测当前页。
- 连接节点为主出口。
- 更换主出口节点。
- 断开主出口节点。
- 主出口锁定设置：
  - 自动配置
  - 固定 IP
  - 固定地区
  - 多节点模式
  - 偏好 IP 类型
  - 多节点并发数量
- 多出口代理实例：
  - 为节点启动独立代理端口
  - 停止实例
  - 更换实例节点
  - 为实例独立锁定国家和 IP 类型
  - 查看出口 IP、出口延迟和检测错误
- 网关面板：
  - Web 管理服务状态
  - 本地代理网关状态
  - OpenVPN 核心连接状态
  - 节点同步守护线程状态
  - 出口检测守护线程状态
  - 延迟测速守护线程状态
  - 多节点维护线程状态
- 日志面板：
  - 全部日志
  - 代理相关日志，包括 `Proxy` 和 `MultiProxy`
  - VPN 连接日志
  - 系统运行日志
  - 一键复制和导出

## 代理使用

默认主代理端口：

```text
7928
```

协议：

- HTTP
- SOCKS5

本机使用示例：

```bash
export http_proxy=socks5://127.0.0.1:7928
export https_proxy=socks5://127.0.0.1:7928
```

如果浏览器或其他客户端在远程设备上使用，需要连接 VPS 公网 IP 和代理端口，并确保防火墙和安全组已放行对应 TCP 端口。

多出口实例会自动分配额外端口，例如 `7929`、`7930`。每个多出口端口对应一个独立 OpenVPN 连接和 TUN 设备。

## 配置与数据路径

默认安装路径：

```text
/opt/aimilivpn
```

默认运行数据路径：

```text
/opt/aimilivpn/vpngate_data
```

关键文件：

| 路径 | 说明 |
| --- | --- |
| `/opt/aimilivpn/vpngate_data/ui_auth.json` | Web 登录账号、密码、安全后缀、端口和锁定规则配置。 |
| `/opt/aimilivpn/vpngate_data/state.json` | 当前运行状态。 |
| `/opt/aimilivpn/vpngate_data/nodes.json` | 候选节点和测速结果。 |
| `/opt/aimilivpn/vpngate_data/multi_proxy.json` | 多出口实例持久化配置。 |
| `/opt/aimilivpn/vpngate_data/configs/` | 运行时生成的 OpenVPN 配置。 |
| `/opt/aimilivpn/vpngate_data/logs/YYYY-MM-DD.json` | Web 日志面板读取的结构化日志。 |
| `/opt/aimilivpn/vpngate_data/vpngate.log` | 主程序 stdout/stderr 运行日志。 |
| `/opt/aimilivpn/vpngate_data/ip_cache.json` | IP 信息补全缓存。 |
| `/opt/aimilivpn/vpngate_auth.txt` | OpenVPN 认证文件。 |

服务环境变量可通过 `/etc/default/aimilivpn` 配置，systemd 服务会读取该文件。

支持的主要环境变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `FETCH_INTERVAL_SECONDS` | `960` | 节点拉取间隔。 |
| `CHECK_INTERVAL_SECONDS` | `960` | 后台可用节点维护间隔。 |
| `TARGET_VALID_NODES` | `3` | 目标可用节点数量。 |
| `MAX_SCAN_ROWS` | `300` | 每轮最多扫描的 VPNGate 行数。 |
| `OPENVPN_TEST_TIMEOUT_SECONDS` | `35` | OpenVPN 连接就绪等待时间。 |
| `OPENVPN_CMD` | `openvpn` | OpenVPN 命令路径。 |
| `OPENVPN_AUTH_USER` | `vpn` | OpenVPN 默认用户名。 |
| `OPENVPN_AUTH_PASS` | `vpn` | OpenVPN 默认密码。 |
| `LOCAL_PROXY_HOST` | `::` | 代理网关监听地址。 |
| `LOCAL_PROXY_PORT` | `7928` | 主代理网关监听端口。 |
| `UI_HOST` | `::` | Web 服务默认监听地址。 |
| `UI_PORT` | `8787` | Web 服务默认监听端口。 |
| `INVALID_BACKOFF_SECONDS` | `1800` | 失效节点黑名单退避时间。 |
| `VPNGATE_DATA_DIR` | `./vpngate_data` | 运行数据目录。 |

注意：Web 配置文件 `ui_auth.json` 中的 Web 端口和安全后缀会覆盖默认 Web 配置。代理网关实际监听地址和主端口由进程启动时的 `LOCAL_PROXY_HOST`、`LOCAL_PROXY_PORT` 决定。

## 运行机制

主程序启动后会创建以下后台任务：

- 代理网关线程：启动主 HTTP/SOCKS5 代理端口。
- 节点同步线程：定期拉取 VPNGate API 并维护可用节点。
- 主出口检测线程：每 30 秒检测主代理出口 IP 和延迟，失败时触发自动切换。
- 活动节点延迟线程：定期刷新活动节点 Ping 延迟。
- 多节点维护线程：每 30 秒检测所有多出口实例，处理锁定规则和故障更换。
- 多出口恢复线程：服务启动后恢复 `multi_proxy.json` 中保存的实例。

主出口锁定规则：

| 模式 | 行为 |
| --- | --- |
| 自动配置 | 优先保持当前节点；当前节点失效时自动切换到可用备用节点。 |
| 固定 IP | 尽量保持当前节点，不按地区或类型切换到其他节点。 |
| 固定地区 | 只在指定国家的候选节点中自动切换。 |
| 多节点模式 | 按配置数量自动维护多个出口实例，可结合国家和 IP 类型限制。 |

多出口实例锁定规则：

- 每个实例可以独立设置目标国家和 IP 类型。
- 设置后即使全局模式不是多节点模式，该端口也会由多节点维护线程自动保持在线。
- 检测失败会尝试在相同规则下更换到其他可用节点。

## 日志

日志分两类：

1. 运行日志：

```text
/opt/aimilivpn/vpngate_data/vpngate.log
```

2. Web 日志面板读取的结构化日志：

```text
/opt/aimilivpn/vpngate_data/logs/YYYY-MM-DD.json
```

结构化日志按行写入 JSON，字段包括：

- `timestamp`
- `level`
- `module`
- `message`

日志模块包括：

- `Main`
- `Routing`
- `VPN`
- `Proxy`
- `MultiProxy`

日志文件会自动清理 3 天前的旧 JSON 日志。

多出口实例每 30 秒会写入检测日志，例如：

```text
[INFO] [MultiProxy] 多出口实例 mp_xxx (端口 7929) 30秒检测正常，出口 IP: x.x.x.x，延迟: 700 ms
```

## 卸载

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Guozh1peng/aimili-vpngate/main/uninstall.sh)
```

也可以使用：

```bash
ml uninstall
```

卸载会删除：

- AimiliVPN 服务
- `/usr/bin/ml`
- `/opt/aimilivpn`
- `rp_filter` 相关 sysctl 配置

卸载前请确认不再需要现有节点数据、账号密码和多出口配置。

## 常见问题

### 无法创建 TUN 设备

常见错误：

```text
Cannot allocate TUN/TAP dev
Cannot open tun/tap dev
```

处理方式：

- 在 VPS 控制面板启用 TUN/TAP。
- 如果是 LXC/OpenVZ/Docker 环境，需要宿主机授予 TUN 权限。
- 确认服务以 root 权限运行。

### Web 后台打不开

检查项：

- 服务是否运行：`ml status`
- Web 端口是否正确：查看 `/opt/aimilivpn/vpngate_data/ui_auth.json`
- 系统防火墙是否放行 Web 端口，默认 `8787/tcp`
- 云服务商安全组是否放行 Web 端口
- 安全后缀是否正确

### 代理端口连不上

检查项：

- 服务是否运行：`ml status`
- 网关面板是否显示本地代理网关运行中
- 系统防火墙和安全组是否放行代理端口，默认 `7928/tcp`
- OpenVPN 是否已经连接成功
- TUN 设备是否存在

### 节点池为空或 API 拉取失败

可能原因：

- VPS DNS 异常。
- 无法访问 `www.vpngate.net`。
- 网络或防火墙干扰 HTTPS/TLS。

处理方式：

- 查看 Web 日志或 `ml logs` 中的错误代码。
- 尝试修复 `/etc/resolv.conf`。
- 检查 VPS 出站网络。
- 更换网络环境或 VPS。

### VPN 已连接但代理无法上网

可能原因：

- 严格 `rp_filter=1` 导致策略路由回包被丢弃。
- iptables 默认策略阻断出站或转发。
- OpenVPN 节点本身失效。
- 当前代理端口对应的 TUN 设备不存在。

处理方式：

- 运行 `ml restart`。
- 查看 Web 网关面板。
- 查看 `ml logs`。
- 确认 `/proc/sys/net/ipv4/conf/all/rp_filter` 为 `2` 或 `0`。

### 多出口没有日志

新版本会在每个多出口实例的 30 秒检测周期写入 `MultiProxy` 日志。Web 日志弹窗中选择“全部日志”或“代理相关”即可查看。

如果仍看不到：

- 确认后台已经更新到最新版本。
- 重启服务：`ml restart`
- 等待至少 30 秒。
- 确认当前确实存在多出口实例。

## English Quick Start

AimiliVPN is a Python-based VPNGate OpenVPN manager with a built-in Web UI and HTTP/SOCKS5 proxy gateway.

Install on a Linux VPS as root:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Guozh1peng/aimili-vpngate/bate/install.sh)
```

Common commands:

```bash
ml
ml status
ml logs
ml restart
ml update
ml password
ml uninstall
```

Default ports:

- Web UI: `8787`
- HTTP/SOCKS5 proxy: `7928`
- Additional multi-exit proxy ports: `7929`, `7930`, ...

Default paths:

- Install directory: `/opt/aimilivpn`
- Runtime data: `/opt/aimilivpn/vpngate_data`
- Service log: `/opt/aimilivpn/vpngate_data/vpngate.log`
- Web log JSON files: `/opt/aimilivpn/vpngate_data/logs/YYYY-MM-DD.json`

Requirements:

- Linux VPS with root access
- TUN/TAP enabled
- Python 3
- OpenVPN
- iproute2, iptables, curl, git

## 许可证

本项目使用 GPL 许可证。详见 [LICENSE](LICENSE)。
