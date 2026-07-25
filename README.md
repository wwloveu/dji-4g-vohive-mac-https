# dji-4g-vohive-mac-https

在 **Apple Silicon Mac mini** 上，把大疆 4G 模块（`2ca3:4006` → `2c7c:0125`）接入 Linux，部署 **VoHive**，并支持：

- VoHive 网页管理（短信 / 模组状态）
- 一键切 **ECM** 网卡模式（给 Mac / 尝试直连 iPad Pro 上网）
- 局域网 / iPad 访问管理后台

本仓库是基于 [wlzh/dji-4g-vohive-mac](https://github.com/wlzh/dji-4g-vohive-mac) 在实机上的落地记录与脚本，针对：

- Mac mini arm64
- QEMU/HVF（非仅 UTM 文档路径）
- 上游 `iniwex5/vohive-release` 官方二进制失效后的 **arm64 离线安装包**

> 免责声明：仅供个人技术测试。涉及蜂窝模组、短信与流量，风险与资费自负。

## 目录

```text
docs/                  部署与使用说明
scripts/               启停 VM、ECM/VoHive 切换
vohive-offline-arm64/  arm64 离线安装资产
```

## 快速使用（本机已部署过）

```bash
# 启动 VoHive VM（QEMU）
./scripts/start-vohive-vm.sh

# 打开后台
open http://127.0.0.1:7575
# 默认账号 admin / admin（请立刻改密）

# iPad 同网访问（示例）
# http://<Mac局域网IP>:7575

# 切 ECM（USB 网卡模式，给 Mac/iPad 上网尝试）
./scripts/switch-to-ecm.sh

# 切回 VoHive（短信/保号）
./scripts/switch-to-vohive.sh

# 停止 VM
./scripts/stop-vohive-vm.sh
```

## 文档

- [部署结果](docs/DEPLOYMENT.md)
- [ECM 模式说明](docs/ECM模式说明.md)
- [iPad 使用说明](docs/IPAD使用说明.md)

## 模式说明

| 模式 | 用途 | 同时性 |
|---|---|---|
| VoHive / QMI (`usbnet=0`) | 短信、模组管理 | 与 ECM 互斥 |
| ECM/NCM (`usbnet=1`) | USB 网卡上网（Mac / 尝试 iPad Pro） | 与 VoHive 互斥 |

**iPad Pro 直插上网**：不是 iPad 原生 4G 棒驱动，而是模组先被 AT 改成 USB 网卡（ECM/NCM），再被 iPad 识别为以太网设备。直连通常比扩展坞更稳；AT 配置两者相同。

## 离线安装 VoHive（arm64 Linux）

在 Ubuntu arm64 中：

```bash
cd vohive-offline-arm64
sudo bash install.sh
```

二进制来源：镜像发布 `6mb/vohive-release` 的 linux_arm64 资产（因官方 release 资源已不可用）。

改大疆模组身份（一次性）：

```bash
sudo bash setup-eg25.sh
```

## 环境记录（作者机器）

- Mac mini · Apple Silicon · macOS
- 模组：大疆 1 代 4G / Baiwang，改写后 `2c7c:0125`
- 虚拟化：`qemu-system-aarch64` + HVF
- 端口转发：`2222→22`，`7575→7575`
- SSH：`ssh -i ~/.ssh/id_ed25519_vohive -p 2222 ubuntu@127.0.0.1`

## 致谢

- [wlzh/dji-4g-vohive-mac](https://github.com/wlzh/dji-4g-vohive-mac)
- [iniwex5/vohive-release](https://github.com/iniwex5/vohive-release)（上游概念与安装结构）
- [6mb/vohive-release](https://github.com/6mb/vohive-release)（可用 arm64 二进制镜像）

## License

文档与脚本以 CC-BY-4.0 分享（与参考仓库一致）。  
VoHive 二进制遵循其上游许可。
