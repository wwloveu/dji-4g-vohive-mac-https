# 在 iPad 上使用 VoHive

## 前提
1. Mac mini 上 VoHive 虚拟机在运行  
2. iPad 和 Mac mini 连在**同一个局域网**（同一路由/Wi‑Fi）  
3. 浏览器访问的是 **Mac 的局域网 IP + 7575 端口**，不是 127.0.0.1

> `127.0.0.1` 只代表“这台设备自己”。  
> 在 Mac 上可以，在 iPad 上必须用 Mac 的局域网地址。

## 同网使用（推荐，最简单）

### 1. 确认 Mac 已启动 VoHive
在 Mac 终端执行：
```bash
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/start-vohive-vm.sh
```
看到 `Web: http://127.0.0.1:7575` 后等 10–20 秒。

### 2. 在 iPad Safari 打开
当前这台 Mac mini 的局域网地址是：

- **http://192.168.50.39:7575**

账号密码：
- 用户名：`admin`
- 密码：`admin`（请登录后立刻改掉）

### 3. 加到主屏幕（像 App 一样）
1. iPad Safari 打开上面的地址并登录  
2. 点分享按钮  
3. 选择「添加到主屏幕」  
4. 以后从主屏幕图标进入即可  

## 如果 iPad 打不开

按顺序排查：

1. **iPad 是否同一网段**  
   - Mac 是有线 `192.168.50.x`  
   - iPad 应连同一路由下的 Wi‑Fi（例如 `wwwww_5G` 对应的同一家庭网）  
   - 若 iPad 在访客 Wi‑Fi / 手机热点 / 公司隔离网，通常访问不到

2. **Mac 上服务是否还活着**  
   在 Mac 浏览器先打开 `http://127.0.0.1:7575`  
   - 本机都打不开：先运行启动脚本  
   - 本机可以、iPad 不行：多半是网络隔离或 IP 变了

3. **IP 是否变了**  
   路由器重启后 Mac IP 可能变化。在 Mac 终端查：
   ```bash
   ipconfig getifaddr en0
   ```
   然后 iPad 改成 `http://新IP:7575`

4. **防火墙**  
   当前已关闭系统防火墙；若你以后打开防火墙，需要允许 `qemu-system-aarch64` 传入连接。

## 出门在外用 iPad（不在家）

同网方案不够，需要“远程安全入口”，任选其一：

### 方案 A：Tailscale（最推荐）
1. Mac 和 iPad 都安装并登录同一 Tailscale 账号  
2. 看 Mac 的 Tailscale IP（100.x.y.z）  
3. iPad 打开：`http://100.x.y.z:7575`

### 方案 B：路由器端口转发 / 公网 HTTPS
- 需要公网 IP 或动态域名  
- 必须上 HTTPS + 强密码，不建议裸 HTTP 暴露到公网  
- 比 Tailscale 麻烦，安全性要求更高

## 安全建议
- 立刻改掉默认 `admin/admin`
- 仅内网或 VPN（Tailscale）访问，不要直接把 7575 映射到公网
- Mac 睡眠可能导致服务不可用；需要长期用可设置「防止自动睡眠」或接电源保持唤醒

## 常用命令（Mac）
```bash
# 启动
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/start-vohive-vm.sh

# 停止
/Users/wwloveu/Documents/Codex/2026-07-25/wwloveu-dji-4g-vohive-mac-https/work/utm-build/stop-vohive-vm.sh

# 看当前局域网 IP
ipconfig getifaddr en0
```
