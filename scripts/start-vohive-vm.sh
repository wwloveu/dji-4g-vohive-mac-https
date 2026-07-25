#!/bin/bash
set -euo pipefail
LOGDIR="/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build"
ROOT="$LOGDIR/vohive-ubuntu.utm/Data"
EFI_CODE="/opt/homebrew/Cellar/qemu/11.0.3/share/qemu/edk2-aarch64-code.fd"
QEMU="/opt/homebrew/bin/qemu-system-aarch64"
PIDFILE="$LOGDIR/qemu.pid"
LOG="$LOGDIR/qemu-out.log"

if [[ ! -x "$QEMU" ]]; then
  echo "qemu not found: $QEMU" >&2
  exit 1
fi
if [[ ! -f "$ROOT/ubuntu-vohive.qcow2" ]]; then
  echo "disk missing: $ROOT/ubuntu-vohive.qcow2" >&2
  exit 1
fi

if pgrep -f "qemu-system-aarch64 -name vohive" >/dev/null 2>&1; then
  echo "vohive VM already running: $(pgrep -f 'qemu-system-aarch64 -name vohive')"
  exit 0
fi

# clear stale pid
[[ -f "$PIDFILE" ]] && rm -f "$PIDFILE" || true

# Prefer Quectel identity; fall back to DJI identity if not yet rewritten
USB_ARGS=(-device qemu-xhci,id=xhci -device usb-host,bus=xhci.0,vendorid=0x2c7c,productid=0x0125)

# Detach fully from controlling terminal / agent session
/usr/bin/nohup "$QEMU" \
  -name vohive \
  -machine virt,gic-version=3,highmem=on \
  -accel hvf \
  -cpu host \
  -smp 2 \
  -m 2048 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$EFI_CODE" \
  -drive if=pflash,format=raw,unit=1,file="$ROOT/efi_vars.fd" \
  -device virtio-blk-pci,drive=root,bootindex=0 \
  -drive if=none,id=root,format=qcow2,file="$ROOT/ubuntu-vohive.qcow2" \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::7575-:7575 \
  -device virtio-rng-pci \
  "${USB_ARGS[@]}" \
  -display none \
  -monitor none \
  -serial null \
  </dev/null >>"$LOG" 2>&1 &
echo $! > "$PIDFILE"
# renice optional
disown %% 2>/dev/null || true
sleep 1
if pgrep -f "qemu-system-aarch64 -name vohive" >/dev/null; then
  echo "started pid=$(pgrep -f 'qemu-system-aarch64 -name vohive' | tr '\n' ' ')"
  echo "Web: http://127.0.0.1:7575  admin/admin"
  echo "SSH: ssh -i ~/.ssh/id_ed25519_vohive -p 2222 ubuntu@127.0.0.1"
else
  echo "failed to start; see $LOG" >&2
  tail -50 "$LOG" >&2 || true
  exit 1
fi
