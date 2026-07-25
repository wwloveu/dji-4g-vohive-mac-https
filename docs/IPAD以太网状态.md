# iPad Pro 以太网上网 — 当前状态（未完成）

更新时间：2026-07-25

## 结论
**还没做好。**  
目前只能做到“模组可被识别 / 可切模式”，**还不能稳定给 iPad Pro 提供可用公网**。

## 已完成
1. 模组身份已永久改写为 `2c7c:0125`（Quectel/Baiwang）
2. VoHive Linux VM 可运行，AT 口可用
3. 可切换：
   - `usbnet=0` QMI（VoHive / Linux 拨号）
   - `usbnet=1` ECM（Mac/iPad 以太网形态）
4. ECM 下 Mac 曾成功出现 **Baiwang** 网卡，并拿到：
   - IP：`192.168.225.x`
   - 网关：`192.168.225.1`（可 ping）
5. 参考 GitHub 说明后的本机脚本已落地：
   - `scripts/switch-to-ecm.sh`
   - `scripts/switch-to-vohive.sh`
   - `scripts/eg25-status.sh`

## 未完成（卡点）
### 1) 公网不通
在 ECM 下：
- 本地网关 `192.168.225.1` 通
- 访问 `1.1.1.1` / `api.ipify.org` 失败
- 错误：`Destination Net Unreachable`（模组网关自己回的）

在 QMI 下：
- 能建立数据会话并拿到蜂窝地址（如 `10.x.x.x`）
- 仍无法稳定 ping/curl 公网

### 2) 百旺固件限制
模组实测信息：
- 厂商：`Baiwang`
- 型号：`QDC507`
- `AT+QNETDEVCTL`：**不支持 / 报 ERROR**
- 标准移远“开 NAT + 自动拨号”路径在这颗固件上走不通

### 3) 当前机态
最近一次检查：
- VM：已停止
- USB：主机能看到 `Baiwang 2c7c:0125`
- 但 **没有 Baiwang 以太网口 / en10**  
  → 说明此刻大概率不在可用 ECM 网卡状态（更像 QMI 或枚举未完成）

## 这意味着什么
- **“识别成以太网”**：以前做过，路径是对的（ECM）
- **“iPad 能上网”**：还没闭环  
  因为蜂窝数据出口（WAN/NAT）没打通

## 下一步（优先）
1. 确认 SIM 是否有**可用流量**（不是纯保号/仅短信）
2. 用 root 重新完整接管 USB，切回 ECM，并验证：
   - Mac 出现 Baiwang + `192.168.225.x`
   - 经 `en*` 能打开公网页
3. Mac 验证通过后，再：
   - 拔掉模组
   - USB-C 直连 iPad Pro
   - 看“以太网”是否获取 IP 并能上网

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
1. Mac 上 Baiwang 有 `192.168.225.x`
2. `curl --interface <该网卡> https://api.ipify.org` 返回公网 IP
3. 拔到 iPad Pro 后，设置里出现以太网并获得 IP
4. iPad Safari 能打开网页
