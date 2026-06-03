#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}错误: 必须以 root 权限运行此脚本。请使用: sudo bash $0${PLAIN}"
    exit 1
fi

echo -e "${BLUE}==========================================================${PLAIN}"
echo -e "${BLUE}        AimiliVPN 一键卸载脚本${PLAIN}"
echo -e "${BLUE}==========================================================${PLAIN}"

INSTALL_DIR="/opt/aimilivpn"

echo -e "\n${YELLOW}警告：此操作将完全删除 AimiliVPN，包括：${PLAIN}"
echo -e "  - 所有 VPN 连接和代理服务"
echo -e "  - 所有配置文件和节点数据"
echo -e "  - 多出口代理实例"
echo -e "  - 系统服务 (systemd/OpenRC)"
echo -e "  - ml 命令快捷接口"

read -p "确定要完全卸载 AimiliVPN 吗？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}已取消卸载。${PLAIN}"
    exit 0
fi

echo -e "\n${YELLOW}[1/5] 正在停止所有服务...${PLAIN}"

if command -v systemctl >/dev/null 2>&1; then
    systemctl stop aimilivpn.service 2>/dev/null || true
elif command -v rc-service >/dev/null 2>&1; then
    rc-service aimilivpn stop 2>/dev/null || true
fi

killall openvpn 2>/dev/null || true

echo -e "${GREEN}  -> 所有服务已停止${PLAIN}"

echo -e "\n${YELLOW}[2/5] 正在删除系统服务...${PLAIN}"

if command -v systemctl >/dev/null 2>&1; then
    systemctl disable aimilivpn.service 2>/dev/null || true
    rm -f /lib/systemd/system/aimilivpn.service
    systemctl daemon-reload
    echo -e "${GREEN}  -> systemd 服务已删除${PLAIN}"
elif command -v rc-service >/dev/null 2>&1; then
    rc-update del aimilivpn default 2>/dev/null || true
    rm -f /etc/init.d/aimilivpn
    echo -e "${GREEN}  -> OpenRC 服务已删除${PLAIN}"
fi

echo -e "\n${YELLOW}[3/5] 正在删除 ml 命令...${PLAIN}"
rm -f /usr/bin/ml
echo -e "${GREEN}  -> ml 命令已删除${PLAIN}"

echo -e "\n${YELLOW}[4/5] 正在清理网络配置...${PLAIN}"

if [ -f "/etc/sysctl.d/99-aimilivpn.conf" ]; then
    rm -f /etc/sysctl.d/99-aimilivpn.conf
    sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true
    echo -e "${GREEN}  -> sysctl 配置已清理${PLAIN}"
fi

if grep -q "net.ipv4.conf.all.rp_filter" /etc/sysctl.conf 2>/dev/null; then
    sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1 || true
    echo -e "${GREEN}  -> sysctl.conf 已清理${PLAIN}"
fi

echo -e "\n${YELLOW}[5/5] 正在删除安装目录...${PLAIN}"

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}  -> 安装目录已删除: $INSTALL_DIR${PLAIN}"
else
    echo -e "${YELLOW}  -> 安装目录不存在${PLAIN}"
fi

echo -e "\n${GREEN}==========================================================${PLAIN}"
echo -e "${GREEN}             AimiliVPN 已完全卸载！${PLAIN}"
echo -e "${GREEN}==========================================================${PLAIN}"
echo -e ""
echo -e "如需重新安装，请运行："
echo -e "  bash <(curl -Ls https://raw.githubusercontent.com/Guozh1peng/aimili-vpngate/main/install.sh)"
echo -e ""