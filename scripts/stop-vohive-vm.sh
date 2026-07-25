#!/bin/bash
pkill -f "qemu-system-aarch64 -name vohive" 2>/dev/null || true
echo stopped
