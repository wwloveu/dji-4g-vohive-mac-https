#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq socat usbutils
echo "[*] 当前 USB 设备:"
lsusb || true
if lsusb | grep -qi '2c7c:0125'; then
  echo "[✓] 已是 Quectel EC25 身份"
  exit 0
fi
if ! lsusb | grep -qi '2ca3:4006'; then
  echo "[!] 未发现大疆模组 2ca3:4006，请先 USB 直通进 VM"
  lsusb
  exit 1
fi
modprobe option
echo 2ca3 4006 > /sys/bus/usb-serial/drivers/option1/new_id || true
sleep 1
# find ttyUSB*
ls -l /dev/ttyUSB* || true
PORT=""
for p in /dev/ttyUSB2 /dev/ttyUSB1 /dev/ttyUSB0 /dev/ttyUSB3; do
  if [ -e "$p" ]; then PORT=$p; break; fi
done
if [ -z "$PORT" ]; then
  echo "[!] 没有 ttyUSB 串口"
  exit 1
fi
echo "[*] 使用串口 $PORT 改 USB 身份"
echo 'AT+QCFG="usbcfg",0x2C7C,0x0125,1,1,1,1,1,0,0' | socat - ${PORT},crnl
sleep 1
echo 'AT+CFUN=1,1' | socat - ${PORT},crnl || true
echo "[*] 已发送重启，等待重新枚举..."
sleep 8
lsusb || true
