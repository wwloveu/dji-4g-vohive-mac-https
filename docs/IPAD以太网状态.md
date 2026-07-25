# iPad Pro 以太网上网 — 当前状态（未完成）

更新时间：2026-07-26

## 结论
**还没做好。**  
目前已确认模组能给主机提供 ECM 以太网和 DHCP 地址，但**还不能给 iPad Pro 提供可用公网**。

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

## 未完成（卡点）
### 1) 公网不通
在 ECM 下：
- 本地网关 `192.168.225.1` 通
- 强制经 `en10` 访问 `1.1.1.1` / `api.ipify.org` 失败
- 错误：`Destination Net Unreachable`（模组网关自己回的）
- `route -n get 1.1.1.1 -ifscope en10` 已确认默认网关为 `192.168.225.1`，因此不是 Mac 路由或 DNS 选路问题

在 QMI 下：
- 能建立数据会话并拿到蜂窝地址（如 `10.x.x.x`）
- 仍无法稳定 ping/curl 公网

### 2) 百旺固件限制与 AT 口占用
模组实测信息：
- 厂商：`Baiwang`
- 型号：`QDC507`
- `AT+QNETDEVCTL`：**不支持 / 报 ERROR**
- 标准移远“开 NAT + 自动拨号”路径在这颗固件上走不通
- VM 内 `ModemManager` 会独占 `/dev/ttyUSB2`；发 AT 前必须停止它，否则 `socat` 返回 `Device or resource busy`

### 3) 当前机态
最近一次检查：
- 已恢复到 `usbnet=0` QMI 模式
- VM：运行中；`/dev/cdc-wdm0` 已出现
- VoHive：`active`
- 上一次 ECM 测试的 `en10` DHCP 地址为 `192.168.225.24`，但其 WAN 仍不可用

### 4) 直连 iPad 的结论
已在确认可用的电信 SIM 上读取到：
- 运营商：`CHN-CT` (`46011`)
- APN：`CTNET`
- PDP：CID 1 已激活，模块地址为 `10.27.77.73`

即使上述状态全部正常，ECM 网关仍拒绝公网路由。该 QDC507 固件对
`AT+QNETDEVCTL`、`AT+QCFG="nat"`、`AT+QICSGP` 均返回 `ERROR`，无法把
PDP 会话自动转发到 USB ECM 网口。

因此，**模块 USB-C 直插 iPad Pro 不能成为独立公网方案**。可行架构是由
Linux/macOS 中转设备用 AT 串口建立 PPP 数据连接，再向 iPad 提供 Wi-Fi 或以太网。

## 这意味着什么
- **“识别成以太网并获得地址”**：已经实测完成（ECM + DHCP）
- **“iPad 能上网”**：还没闭环  
  因为模块侧蜂窝数据出口（WAN/NAT）没打通；将模组插到 iPad 前无法绕过这个问题

## 下一步（优先）
1. 确认当前 SIM/APN 的蜂窝数据权限和套餐状态；QMI 虽能拿到 `10.x.x.x`，但 ECM 与 QMI 的公网探测都被上游网关拒绝。
2. 在不修改现有 APN 的前提下，获取这颗 QDC507 固件可用的模块侧自动拨号/数据出口配置；`QNETDEVCTL` 不是该固件可用路径。
3. 部署独立中转设备（OpenWrt 旅行路由器或树莓派）：
   - 通过 AT 串口/PPP 拨号使用 `CTNET`
   - 以 Wi-Fi 或以太网向 iPad 提供网络
   - 验证该设备和 iPad 的公网访问

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
只有同时满足才算做好：
1. Mac 上 Baiwang 有 `192.168.225.x`（已完成）
2. `curl --interface <该网卡> https://api.ipify.org` 返回公网 IP（未完成）
3. 中转设备 PPP 获取公网并开启 Wi-Fi/以太网（待部署）
4. iPad 通过中转设备打开网页（待部署）
