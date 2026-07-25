# ECM 切换结果

## 已完成
1. VoHive 已停止  
2. 已发送并确认：
   - `AT+QCFG="usbnet"` 原值 `0`（QMI）
   - `AT+QCFG="usbnet",1` → `OK`（ECM/NCM 网卡模式）
   - `AT+CFUN=1,1` 软重启
3. SIM：`READY`，附着：`CGATT=1`，APN 上下文含 **CTNET**（电信）
4. macOS 识别为硬件端口 **Baiwang**，网卡多为 `en10`
5. 典型地址：`192.168.225.x`，网关 `192.168.225.1`（移远模组常见网段）

## 当前含义
- **USB 网卡模式已成功**（这是给 Mac / iPad 当“有线网卡”用的关键一步）
- 本机到模组网关 `192.168.225.1` 可通
- **蜂窝公网**是否已自动拨上，还需你这边看 Baiwang 能否打开外网；若不能，通常还要补一次数据拨号（`QNETDEVCTL`），可能需再进 Linux 发 AT

## 现在请你这样试 iPad Pro
1. 看 Mac「系统设置 → 网络」是否有 **Baiwang**，并有 IP  
2. **从 Mac 拔掉模组**  
3. **USB-C 直连**插到 iPad Pro（先不要扩展坞）  
4. iPad：设置里找「以太网」/相关 USB 网络，看是否获取 IP  
5. 能打开网页 = 成功  

## 短信
ECM 下一般不能在 iPad 上直接收短信。  
要短信时插回 Mac，运行：

```bash
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/switch-to-vohive.sh
```

再打开 `http://127.0.0.1:7575`

## 相关脚本
- 切 ECM：`.../work/utm-build/switch-to-ecm.sh`
- 切回 VoHive：`.../work/utm-build/switch-to-vohive.sh`
