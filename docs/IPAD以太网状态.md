# iPad Pro 以太网上网 - 实测状态

更新时间：2026-07-26

## 结论

**iPad 已能识别模块为标准 CDC-ECM 以太网并取得 DHCP 地址，但当前 QDC507 固件不能把 ECM 客户端流量转发到蜂窝公网。独立 iPad 直连上网尚未实现。**

这不是 iPad 驱动、USB 线、DNS 或 APN 配置问题。模块的蜂窝 PDP 已正常激活；断点在模块内的 `192.168.225.1` ECM 网关转发。

## 当前配置

```text
AT+QCFG="usbcfg",0x2C7C,0x0125,1,1,1,1,1,0,0
AT+QCFG="usbnet",1
AT+CFUN=1,1
```

- USB 身份：`2c7c:0125`（Quectel EC25 兼容身份）
- AT 固件：`QDC507GLEFM21`，不是标准 Quectel EC25/EG25 固件
- macOS：`Baiwang/en10`，原生 `AppleUserECM`
- iPad：`Baiwang` 以太网，DHCP 获得 `192.168.225.x/24`，网关 `192.168.225.1`
- ECM 描述符：控制接口 `class 2/subclass 6`，数据接口 `class 10`

## 已验证证据

1. iPad 显示以太网，自动获得 IP、掩码和路由器地址。
2. Mac 绑定 ECM 接口可稳定 ping `192.168.225.1`。
3. 通过 ECM 接口访问 `1.1.1.1` 和 HTTPS 均超时；因此不是 DNS 问题。
4. 蜂窝侧正常：`CHN-CT (46011)`、`CTNET`、`AT+CGATT?` 为 `1`、CID 1 已激活，且已获得运营商分配地址和 DNS。
5. 标准 EC25 网络控制命令均不可用：`AT+QNETDEVCTL?`、`AT+QCFG="nat"`、`AT+QICSGP?` 返回 `ERROR`；`AT+CGACT=0,1` 和 `AT+CGACT=1,1` 也返回 `ERROR`。

## 已排除

- 将 USB 身份临时改回大疆原厂 `2ca3:4006` 后，仍获得相同 DHCP/网关但无法访问公网；身份伪装不是根因。
- 一份新建教程建议把 `usbcfg` 最后一位设为 `1`。实测它不暴露 CDC 网络接口，已回滚。
- 手工设置中国电信 DNS 后网页仍无连接进度，DNS 不是断点。

## 可行路径

### 独立 iPad

当前没有经过验证的安全 AT 修复。标准 Quectel EG25-G 恢复包需要 fastboot 或 Qualcomm EDL，且公开实测资料警告 DJI/Baiwang 模块不能直接刷标准 Quectel 固件；在没有 QDC507 专用 EDL 包、分区备份和硬件救砖路径前，**禁止刷写通用 EG25/EC25 固件**。

### 非独立 iPad

QDC507 已有可验证的 PPP 出网路径：使用 Linux/macOS 主机通过 `ATD*99#` 拨号，再由主机做网络共享给 iPad。该方案能联网，但不满足“模块直连 iPad、无需中间主机”。

## 脚本

```bash
# 切到 ECM（仅让 Mac/iPad 识别为以太网；不保证公网转发）
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/repo/scripts/switch-to-ecm.sh

# 切回 VoHive/QMI
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/repo/scripts/switch-to-vohive.sh
```

## 参考

- https://github.com/flxxyz/dji-4g-modem
- https://github.com/CdricZhang/dji-cellular-as-modem
- https://github.com/KirisameLonnet/qdc507-macos-serial-driver
- https://github.com/Biktorgj/quectel_eg25_recovery
- https://blog.sparktour.me/posts/2026/07/04/dji-baiwang-eg25-asterisk-telegram-sms-gateway/
