#!/bin/bash

# --- 自动释放文件逻辑 ---
# 检查当前目录下是否包含核心文件夹 agent (这是判断目录是否为空的标志)
if [ ! -d "/home/user/agent" ]; then
    echo "检测到挂载目录为空，正在初始化程序文件..."
    # 将备份的文件静默拷贝回当前家目录
    cp -rp /app_archive/. /home/user/
    echo "初始化完成。"
else
    echo "挂载目录已存在数据，跳过初始化。"
fi

# --- 原有的启动逻辑 ---
echo "--- 诊断并修复 Hermes 环境 ---"
hermes doctor --fix || echo "警告：诊断执行失败。"

echo "--- 正在启动 Hermes Web UI ---"
# 设置默认 Token
export AUTH_TOKEN="${WEBUI_TOKEN:-hermes2026}"

# 确保必要的目录存在
mkdir -p /home/user/.hermes-web-ui
LOG_FILE="/home/user/.hermes-web-ui/hermes.log"
touch "$LOG_FILE"

# 启动 Hermes 服务
hermes-web-ui start --port 7860 &

# 容器保活
tail -f "$LOG_FILE"
