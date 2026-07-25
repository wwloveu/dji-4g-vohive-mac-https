#!/bin/bash
# VoHive offline installer for aarch64 (adapted from wlzh backup installer)
set -e
VOHIVE_DIR=/opt/vohive
BIN_PATH=$VOHIVE_DIR/bin/vohive
DATA_DIR=$VOHIVE_DIR/data
CONFIG_PATH=$VOHIVE_DIR/config/config.yaml
SERVICE_PATH=/etc/systemd/system/vohive.service
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
  echo "[!] 请用 root 运行：sudo bash $0"
  exit 1
fi

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
  echo "[!] 当前架构 $ARCH，本包为 aarch64 二进制"
  exit 1
fi

for f in vohive mcc-mnc-table.json; do
  if [ ! -f "$SCRIPT_DIR/$f" ]; then
    echo "[!] 缺少资产文件：$SCRIPT_DIR/$f"
    exit 1
  fi
done

echo "[*] 安装系统依赖：socat usbutils pciutils"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq socat usbutils pciutils

echo "[*] 创建目录 $VOHIVE_DIR"
mkdir -p "$VOHIVE_DIR"/{bin,config,data,logs}

echo "[*] 部署二进制 → $BIN_PATH"
install -m 0755 "$SCRIPT_DIR/vohive" "$BIN_PATH"
install -m 0644 "$SCRIPT_DIR/mcc-mnc-table.json" "$DATA_DIR/mcc-mnc-table.json"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "[*] 写入默认 config.yaml"
  cat > "$CONFIG_PATH" <<'YAML'
bark:
    enabled: false
    group: vohive
    icon: ""
    level: active
    urls: []
email:
    enabled: false
    from_address: ""
    password: ""
    smtp_host: ""
    smtp_port: 0
    to_addresses: []
    username: ""
feishu:
    app_id: ""
    app_secret: ""
    chat_ids: []
    enabled: false
pushplus:
    channel: wechat
    enabled: false
    token: ""
    topic: ""
qq:
    app_id: ""
    app_secret: ""
    direct_ids: ""
    enabled: false
    group_ids: ""
server:
    port: :7575
telegram:
    admin_id: 0
    base_url: ""
    bot_token: ""
    chat_id: 0
    enabled: false
    proxy: ""
web:
    password: "admin"
    username: admin
webhook:
    enabled: false
    headers: {}
    retry_max: 3
    secret: ""
    text_template: '{{device_label}} {{text}}'
    timeout_ms: 5000
    urls: []
devices: []
YAML
  chmod 0600 "$CONFIG_PATH"
  echo "    默认 web 账号：admin / admin"
fi

cat > "$SERVICE_PATH" <<'UNIT'
[Unit]
Description=VoHive Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vohive
ExecStart=/opt/vohive/bin/vohive -c /opt/vohive/config/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now vohive
sleep 2
if systemctl is-active --quiet vohive; then
  echo "[✓] VoHive 已启动: http://$(hostname -I | awk '{print $1}'):7575  admin/admin"
else
  echo "[!] 服务异常: journalctl -u vohive -n 50 --no-pager"
  exit 1
fi
