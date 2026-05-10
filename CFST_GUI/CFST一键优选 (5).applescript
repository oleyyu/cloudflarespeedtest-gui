-- ──────────────────────────────────────────────
-- CloudflareSpeedTest 一键优选 GUI
-- 使用方法：把本文件和 cfst 二进制放在同一目录
--           双击运行（Script Editor 打开后点运行，或导出为 .app）
-- ──────────────────────────────────────────────

-- 找到 .app 所在目录（兼容 .app 和直接运行两种模式）
set appPath to POSIX path of (path to me)
-- 如果是 .app，路径形如 /foo/bar/CFST一键优选.app/，取其父目录
if appPath ends with ".app/" or appPath ends with ".app" then
	set scriptDir to do shell script "dirname " & quoted form of appPath
else
	set scriptDir to do shell script "dirname " & quoted form of appPath
end if

-- 检查 cfst 是否存在
set cfstPath to scriptDir & "/cfst"
try
	do shell script "test -f " & quoted form of cfstPath
on error
	display alert "找不到 cfst" message "请把 cfst 二进制和本脚本放在同一目录。当前查找路径：" & scriptDir as critical
	return
end try

-- 确保 cfst 有执行权限
do shell script "chmod +x " & quoted form of cfstPath

-- ── 步骤 1：读取 hosts 里现有的 CF IP ────────────────
set cfPattern to "(104\\.(1[6-9]|2[0-9]|3[01])\\.|172\\.(6[4-9]|7[01])\\.|162\\.158\\.|198\\.41\\.)"
set currentIP to ""
try
	set currentIP to do shell script "grep -Eo '([0-9]{1,3}\\.){3}[0-9]{1,3}' /etc/hosts | grep -E '" & cfPattern & "' | head -1"
end try

-- ── 步骤 2：主菜单 ────────────────────────────────────
set menuMsg to "Cloudflare IP 优选工具" & return & return
if currentIP is "" then
	set menuMsg to menuMsg & "hosts 中未检测到 Cloudflare IP" & return & "测速完成后需手动添加到 hosts。"
else
	set menuMsg to menuMsg & "当前 CF IP：" & currentIP
end if

set action to button returned of (display dialog menuMsg ¬
	buttons {"退出", "查看测速参数", "开始测速"} ¬
	default button "开始测速" ¬
	with title "CFST 优选" ¬
	with icon note)

if action is "退出" then return

-- ── 步骤 3：参数设置（可选）────────────────────────────
set cfstArgs to "-n 200 -t 4 -dn 10 -dt 10"

if action is "查看测速参数" then
	set paramResult to display dialog "当前测速参数（可直接修改）：" ¬
		default answer cfstArgs ¬
		buttons {"取消", "确认并开始测速"} ¬
		default button "确认并开始测速" ¬
		with title "测速参数"
	if button returned of paramResult is "取消" then return
	set cfstArgs to text returned of paramResult
end if

-- ── 步骤 4：开始测速 ──────────────────────────────────
set resultFile to scriptDir & "/result_hosts.txt"

display dialog "测速即将开始，约需 1-2 分钟。" & return & return & "测速期间窗口会无响应，这是正常现象，请耐心等待，不要关闭。" & return & return & "请确保已关闭所有 VPN / 代理！" ¬
	buttons {"开始"} default button "开始" with title "CFST 优选"

display notification "正在测速，请稍候..." with title "CFST 优选"

do shell script "rm -f " & quoted form of resultFile

try
	do shell script "cd " & quoted form of scriptDir & " && " & quoted form of cfstPath & " " & cfstArgs & " -o " & quoted form of resultFile
on error errMsg
	display alert "测速失败" message errMsg as critical
	return
end try

-- ── 步骤 5：读取结果 ──────────────────────────────────
set bestIP to ""
try
	set bestIP to do shell script "awk -F',' 'NR==2{print $1}' " & quoted form of resultFile
end try

if bestIP is "" then
	display alert "测速结果为空" message "没有找到可用的 IP，请检查网络或调整测速参数后重试。" as warning
	return
end if

set statsLine to ""
set speedVal to "0"
try
	set statsLine to do shell script "awk -F',' 'NR==2{print \"延迟: \" $5 \" ms  |  速度: \" $6 \" MB/s\"}' " & quoted form of resultFile
	set speedVal to do shell script "awk -F',' 'NR==2{print $6}' " & quoted form of resultFile
end try

-- 速度为 0 时提示 VPN 问题
if speedVal is "0.00" or speedVal is "0" then
	display alert "测速失败" message "下载速度为 0 MB/s，请关闭 VPN / 代理后重试。" as critical
	return
end if

-- ── 步骤 6：展示结果 ──────────────────────────────────
set confirmMsg to "测速完成！" & return & return & "最优 IP：" & bestIP & return
if statsLine is not "" then
	set confirmMsg to confirmMsg & statsLine & return
end if

if currentIP is "" then
	set confirmMsg to confirmMsg & return & "hosts 中没有旧 CF IP 可替换。" & return & "请手动将此 IP 添加到 /etc/hosts。"
	set copyAction to button returned of (display dialog confirmMsg ¬
		buttons {"关闭", "复制 IP"} ¬
		default button "复制 IP" ¬
		with title "测速结果")
	if copyAction is "复制 IP" then
		set the clipboard to bestIP
		display notification "IP 已复制到剪贴板" with title "CFST 优选"
	end if
	return
end if

if currentIP is bestIP then
	display dialog confirmMsg & return & "当前 IP 已是最优，无需替换！" ¬
		buttons {"好的"} default button "好的" with title "无需更新"
	return
end if

-- ── 步骤 7：确认替换 ──────────────────────────────────
set confirmMsg to confirmMsg & return & "旧 IP：" & currentIP & return & "新 IP：" & bestIP & return & return & "确认替换 /etc/hosts？（需要管理员密码）"

set confirmBtn to button returned of (display dialog confirmMsg ¬
	buttons {"取消", "替换"} ¬
	default button "替换" ¬
	with title "确认替换")

if confirmBtn is "取消" then return

-- ── 步骤 8：备份 + 替换 hosts ────────────────────────
try
	do shell script "cp -f /etc/hosts /etc/hosts_backup" with administrator privileges
	do shell script "sed -i '' 's/" & currentIP & "/" & bestIP & "/g' /etc/hosts" with administrator privileges
on error errMsg
	display alert "替换失败" message errMsg as critical
	return
end try

-- ── 完成 ─────────────────────────────────────────────
display notification "hosts 已更新为 " & bestIP with title "优选完成"
display dialog "替换成功！" & return & return & bestIP & " 已写入 /etc/hosts" & return & "旧 hosts 已备份到 /etc/hosts_backup" ¬
	buttons {"完成"} default button "完成" with title "优选完成"
