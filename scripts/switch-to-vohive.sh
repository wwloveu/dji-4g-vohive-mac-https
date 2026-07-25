#!/bin/bash
# ECM -> VoHive/QMI 保号/短信模式
set -euo pipefail
KEY="$HOME/.ssh/id_ed25519_vohive"
SSH=(ssh -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -p 2222 ubuntu@127.0.0.1)
START_VM="/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/start-vohive-vm.sh"
STOP_VM="/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/stop-vohive-vm.sh"

echo "[1/4] 重启 VM 并抢占 USB（QEMU usb-host 2c7c:0125）..."
bash "$STOP_VM" || true
sleep 2
bash "$START_VM"
sleep 10

echo "[2/4] 等待模组进 VM..."
ok=0
for i in $(seq 1 30); do
  if "${SSH[@]}" 'lsusb | grep -q 2c7c:0125' 2>/dev/null; then ok=1; break; fi
  sleep 2
done
if [ "$ok" != 1 ]; then
  echo "❌ 模组未进入 VM。请确认已从 iPad 拔回并插在 Mac 上。"
  exit 1
fi

echo "[3/4] 恢复 VoHive USB 组合 (QMI)..."
"${SSH[@]}" "echo vohive | sudo -S bash -lc '
systemctl stop ModemManager || true
modprobe option || true
# ECM 下 AT 口可能是 ttyUSB2/3，多试
for p in /dev/ttyUSB2 /dev/ttyUSB3 /dev/ttyUSB1 /dev/ttyUSB0; do
  [ -e \$p ] || continue
  printf \"AT\\r\" | socat - \$p,crnl | grep -q OK && PORT=\$p && break
done
echo PORT=\$PORT
[ -n \"\$PORT\" ]
printf \"AT+QCFG=\\\"usbnet\\\",0\\r\" | socat - \$PORT,crnl
sleep 1
printf \"AT+QCFG=\\\"usbcfg\\\",0x2C7C,0x0125,1,1,1,1,1,0,0\\r\" | socat - \$PORT,crnl
sleep 1
printf \"AT+CFUN=1,1\\r\" | socat - \$PORT,crnl || true
'"

echo "[4/4] 模组会重启并短暂离开，重新拉起 VM 连接并启动 VoHive..."
sleep 12
bash "$STOP_VM" || true
sleep 2
bash "$START_VM"
sleep 12
for i in $(seq 1 30); do
  if "${SSH[@]}" 'lsusb | grep -q 2c7c:0125' 2>/dev/null; then break; fi
  sleep 2
done
"${SSH[@]}" "echo vohive | sudo -S bash -lc 'modprobe option || true; systemctl start vohive; systemctl is-active vohive; lsusb | grep 2c7c'"
echo "✅ VoHive 模式：http://127.0.0.1:7575  或  http://192.168.50.39:7575"
