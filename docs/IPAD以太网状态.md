# iPad Pro 以太网上网 — 当前状态（已验收）

更新时间：2026-07-26

## 结论
**已完成。**
大疆模块伪装为 Quectel EC25 后切换到 ECM，iPad Pro 可直接识别并使用蜂窝公网。

## 已完成
1. 模组身份已永久改写为 `2c7c:0125`（Quectel/Baiwang）
2. VoHive Linux VM 可运行，AT 口可用
3. 可切换：
   - `usbnet=0` QMI（VoHive / Linux 拨号）
   - `usbnet=1` ECM（Mac/iPad 以太网形态）
4. 2026-07-26 按上游 AT 路径完成实测：
   - 在 VM 的 `ttyUSB2` 停止 `VoHive` 和 `ModemManager` 后，`AT+QCFG="usbnet",1` 返回 `OK`
   - 停止 root 启动的 QEMU VM 后，Mac 识别到 **Baiwang / en10**
   - 启用 Baiwang DHCP 后，Mac 获得 `192.168.225.24/24`
   - DHCP 网关为 `192.168.225.1`，ICMP 往返正常
5. 参考 GitHub 说明后的本机脚本已落地：
   - `scripts/switch-to-ecm.sh`
    - `scripts/switch-to-vohive.sh`
    - `scripts/eg25-status.sh`
6. 用户提供的 iPad Pro 直连验收截图（2026-07-26）显示：
   - 模组通过 USB-C 直接连接 iPad Pro
   - iPad 获得公网 IP：`101.90.89.178`
   - 网络测速下行约 `131.82 Mbps`，Ping `22 ms`
   - 因此，iPad 的以太网识别和公网访问均已完成

## 已知差异
### Mac/VM 旁路调试不代表 iPad 结果
在 Mac 的 `en10` ECM 调试中曾出现：
- 本地网关 `192.168.225.1` 通
- 强制经 `en10` 访问 `1.1.1.1` / `api.ipify.org` 失败
- 错误：`Destination Net Unreachable`（模组网关自己回的）
- `route -n get 1.1.1.1 -ifscope en10` 已确认默认网关为 `192.168.225.1`，因此不是 Mac 路由或 DNS 选路问题

该现象仅说明 Mac/VM 的旁路接管路径与 iPad 的原生 ECM 路径存在差异，**不能否定 iPad 直连验收结果**。

### AT 口注意事项
模组实测信息：
- 厂商：`Baiwang`
- 型号：`QDC507`
- `AT+QNETDEVCTL`：**不支持 / 报 ERROR**
- VM 内 `ModemManager` 会独占 `/dev/ttyUSB2`；发 AT 前必须停止它，否则 `socat` 返回 `Device or resource busy`

### 3) 当前机态
2026-07-26 曾测试一份新建教程中的 USB 组合：

```text
AT+QCFG="usbcfg",0x2C7C,0x0125,1,1,1,1,1,0,1
AT+CFUN=1,1
```

该组合会让模块枚举为复合 USB 设备，但没有 CDC 网络接口，iPad 不会显示以太网；已回滚，不再使用。

当前已实测可用的 iPad ECM 组合为：

```text
AT+QCFG="usbcfg",0x2C7C,0x0125,1,1,1,1,1,0,0
AT+QCFG="usbnet",1
AT+CFUN=1,1
```

- 模块已重新枚举为 `Baiwang/en10`，由 macOS 原生 `AppleUserECM` 驱动。
- USB 描述符已确认 ECM 控制接口为 `class 2 / subclass 6`，数据接口为 `class 10`，即 iPadOS 原生支持的 CDC-ECM。
- QEMU 已停止；现在可物理拔插并直连 iPad Pro 进行验收。

### iPad 直连验收条件
已在确认可用的电信 SIM 上读取到：
- 运营商：`CHN-CT` (`46011`)
- APN：`CTNET`
- PDP：CID 1 已激活，模块地址为 `10.27.77.73`

即使该固件不支持标准 EC25 的 NAT/网络控制 AT 命令，iPad 的原生 ECM 路径仍已由现场测速验收通过。

## 这意味着什么
- **“识别成以太网并获得地址”**：已完成（ECM + DHCP）
- **“iPad 能上公网”**：已完成（公网 IP 与测速截图已验收）

## 下一步（优先）
1. 保持电信 SIM 的 `CTNET` 数据服务可用。
2. 日常使用时将模块保持在 `usbnet=1` ECM，再直接插入 iPad Pro。
3. VoHive 使用前切回 `usbnet=0` QMI；两种模式不能同时使用。

## 当前可用脚本
```bash
# 切到 ECM（给 Mac / iPad 走以太网形态）
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/repo/scripts/switch-to-ecm.sh

# 看当前是在 Mac/ECM 还是 VM/QMI
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/repo/scripts/eg25-status.sh

# 切回 VoHive/QMI
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/repo/scripts/switch-to-vohive.sh
```

> 说明：仓库里目前没有 `prepare-ipad-ethernet.sh`。当前路径是先用 `switch-to-ecm.sh` 把模组切到 ECM，再用 `eg25-status.sh` 验证网卡和 IP。

## 判定成功标准
已满足的验收标准：
1. Mac 上 Baiwang 有 `192.168.225.x`（已完成）
2. iPad Pro 获得公网 IP（已完成）
3. iPad Pro 完成公网测速（已完成）
