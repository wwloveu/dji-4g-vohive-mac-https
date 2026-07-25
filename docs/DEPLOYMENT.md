# DJI 4G + VoHive 部署结果（Mac Mini arm64）

## 当前状态
- 虚拟机：QEMU/HVF Ubuntu 24.04 arm64（非原来的 HAOS「虚拟机」）
- VoHive：已安装并运行
- 模组：已从 `2ca3:4006` 改写为 Quectel EC25 `2c7c:0125`（永久）
- Web：http://127.0.0.1:7575
- 账号：`admin` / `admin`（请立刻改密）

## 日常启动
```bash
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/start-vohive-vm.sh
```

## SSH
```bash
ssh -i ~/.ssh/id_ed25519_vohive -p 2222 ubuntu@127.0.0.1
```

## 说明
- 你原来的 UTM「虚拟机」是 Home Assistant OS，已保留未覆盖。
- 上游 iniwex5/vohive-release 官方二进制已失效；本次使用镜像 `6mb/vohive-release` 的 arm64 包。
- 端口转发：宿主机 `2222->22`，`7575->7575`。
