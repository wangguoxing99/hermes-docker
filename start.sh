#!/bin/bash

# --- 1. 环境自检与修复 ---
echo "--- 诊断并修复 Hermes 环境 ---"
hermes doctor --fix || echo "警告：诊断执行失败。"

# --- 2. 启动服务 ---
echo "--- 正在启动 Hermes Web UI ---"
if [ -n "$WEBUI_TOKEN" ]; then
    export AUTH_TOKEN="$WEBUI_TOKEN"
else
    export AUTH_TOKEN="hermes2026"
fi

mkdir -p /home/user/.hermes-web-ui
touch "$LOG_FILE"

# 启动 Hermes 服务
hermes-web-ui start --port 7860

# --- 3. 容器保活 ---
tail -f "$LOG_FILE"
