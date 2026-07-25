#!/bin/bash
# VoHive/QMI -> ECM (Mac/iPad 网卡模式)
set -euo pipefail
KEY="$HOME/.ssh/id_ed25519_vohive"
SSH=(ssh -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -p 2222 ubuntu@127.0.0.1)
START_VM="/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/start-vohive-vm.sh"

if ! pgrep -f 'qemu-system-aarch64 -name vohive' >/dev/null; then
  echo "[*] 启动 VM 以便发 AT..."
  bash "$START_VM"
  sleep 8
fi

echo "[1/3] 确认模组在 VM..."
for i in $(seq 1 20); do
  if "${SSH[@]}" 'lsusb | grep -q 2c7c:0125' 2>/dev/null; then break; fi
  # if modem already on Mac ECM, just report
  if networksetup -listallhardwareports | grep -q 'Baiwang'; then
    echo "已经是 ECM/Baiwang 网卡模式"
    ifconfig | grep -A5 'en10:' || true
    exit 0
  fi
  sleep 2
done

echo "[2/3] 停 VoHive 并切换 usbnet=1 ..."
"${SSH[@]}" "echo vohive | sudo -S bash -lc '
systemctl stop vohive || true
modprobe option || true
PORT=/dev/ttyUSB2
[ -e \$PORT ] || PORT=/dev/ttyUSB3
[ -e \$PORT ] || PORT=/dev/ttyUSB1
printf \"AT+QCFG=\\\"usbnet\\\",1\\r\" | socat - \$PORT,crnl
sleep 1
printf \"AT+CFUN=1,1\\r\" | socat - \$PORT,crnl || true
'"

echo "[3/3] 等待 Mac 识别 Baiwang/ECM 网卡..."
for i in $(seq 1 20); do
  if networksetup -listallhardwareports 2>/dev/null | grep -q 'Baiwang'; then
    echo "✅ ECM 模式就绪"
    networksetup -listallhardwareports | awk '/Baiwang/{print; getline; print; getline; print}'
    for n in en5 en6 en7 en8 en9 en10 en11 en12 en13 en14 en15; do
      ip=$(ipconfig getifaddr "$n" 2>/dev/null || true)
      [ -n "$ip" ] && echo "   $n => $ip"
    done
    echo
    echo "下一步（iPad Pro）："
    echo "  1. 确认 Mac 上 Baiwang 有 IP（上面已显示）"
    echo "  2. 从 Mac 拔掉模组"
    echo "  3. USB-C 直连插入 iPad Pro"
    echo "  4. 打开 设置 → 以太网/USB 设备，看是否获取 IP"
    echo "短信：需要时再运行 switch-to-vohive.sh 切回"
    exit 0
  fi
  sleep 2
done
echo "❌ 超时未看到 Baiwang 网卡。可重插模组后重试。"
exit 1
