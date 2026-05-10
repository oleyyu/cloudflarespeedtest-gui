# CFST 优选IP测速 傻瓜式GUI版
# CFST 一键优选

> 基于 [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 的 macOS 傻瓜式 GUI 封装，双击即可完成 Cloudflare IP 测速并自动更新 hosts。
> > 目前仅支持macOS + MacBook M1以上的版本
---


## 功能

- 自动检测 hosts 中现有的 Cloudflare IP
- 一键测速，弹窗显示最优 IP、延迟、下载速度
- 自动备份并替换 `/etc/hosts`
- 本App基于XIU2对CFST，主要功能由XIU2提供。
- 本程序由Claude/ChatGPT制作！
---

## 文件结构

下载后将以下三个文件放在**同一目录**，不需要子文件夹：

```
cfst                  ← CloudflareSpeedTest 二进制
ip.txt                ← Cloudflare IP 段列表
CFST Main.app       ← 本脚本导出的 app
CFST.applescript      ← 开源AppleScript
```


---

## 使用方法

1. **双击 `CFST一键优选.app`**
2. 主界面显示当前 CF IP，点「**开始测速**」
3. 确认已关闭 VPN / 代理，点「**开始**」
4. 等待约 1-2 分钟（**期间窗口无响应属正常现象**）
5. 弹窗显示最优 IP 及速度，点「**替换**」
6. 输入 Mac 开机密码，完成

---

## 首次运行被系统拦截？

双击 CFST main [Run this].app，如果弹出以下提示：

"无法打开，因为来自身份不明的开发者"

**解决方法**：

打开「系统设置」→「隐私与安全性」
往下滑，找到「已阻止 CFST一键优选」
点「仍要打开」→ 输入开机密码确认

---

## 常见问题

**Q：测速失败，速度为 0 MB/s**
A：关闭所有 VPN / 代理后重试。

**Q：提示"找不到 cfst"**
A：确认 `cfst`、`ip.txt`、`CFST一键优选.app` 三个文件在同一目录。

**Q：hosts 中未检测到 Cloudflare IP**
A：测速完成后点「复制 IP」，手动在 `/etc/hosts` 添加一行：
```
104.xx.xx.xx  你的域名.com
```

**Q：多久运行一次？**
A：建议每 1-2 周运行一次，或感觉网速变慢时运行。

---

## 系统要求

- macOS 11 或更高版本
- 无需安装任何依赖

---

## 致谢

- [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) — 核心测速工具

---

## License

MIT
