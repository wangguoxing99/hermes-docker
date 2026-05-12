#!/bin/bash

# --- 变量配置 (严格检查：等号两边严禁空格) ---
BACKUP_NAME="hermes_full_backup.tar.gz"
REPO_ID="$HF_DATASET_ID"
LOG_FILE="/home/user/.hermes-web-ui/server.log"

export NODE_NO_WARNINGS=1
export PATH="/home/user/agent/.venv/bin:$PATH"

# --- 1. 启动时：全量恢复到 /home/user ---
if [ -n "$REPO_ID" ]; then
    echo "正在从 Dataset 恢复数据: $REPO_ID..."
    python3 << END
from huggingface_hub import hf_hub_download
import os
try:
    hf_hub_download(repo_id='$REPO_ID', filename='$BACKUP_NAME', repo_type='dataset', local_dir='.')
    print('下载备份成功。')
except Exception as e:
    print(f'未发现初始备份或下载失败: {e}')
END
    if [ -f "$BACKUP_NAME" ]; then
        echo "正在执行全量数据恢复..."
        # 解压到家目录，tar 会自动跳过已存在的静态文件
        tar -xzf "$BACKUP_NAME" -C /home/user/
        rm "$BACKUP_NAME"
        echo "恢复完成。"
    fi
fi

# --- 2. 运行中：每 10 分钟执行一次“排除法”备份 ---
(
  while true; do
    sleep 600
    echo "--- 正在执行定时全量备份 (排除冗余项) ---"
    # 切换到家目录进行打包，排除掉镜像已有的静态大文件夹
    tar -czf "/tmp/$BACKUP_NAME" -C /home/user \
        --exclude='agent' \
        --exclude='.cache' \
        --exclude='.npm-global' \
        --exclude='.local' \
        --exclude='.cargo' \
        .
    
    python3 << END
from huggingface_hub import HfApi
import os
api = HfApi()
try:
    api.upload_file(
        path_or_fileobj='/tmp/$BACKUP_NAME',
        path_in_repo='$BACKUP_NAME',
        repo_id='$REPO_ID',
        repo_type='dataset',
        token=os.environ.get('HF_TOKEN')
    )
    print('全量备份同步完成。')
except Exception as e:
    print(f'同步失败: {e}')
END
  done
) &

# --- 3. 环境自检与修复 ---
echo "--- 诊断并修复 Hermes 环境 ---"
hermes doctor --fix || echo "警告：诊断执行失败。"

# --- 4. 启动服务 ---
echo "--- 正在启动 Hermes Web UI ---"
if [ -n "$WEBUI_TOKEN" ]; then
    export AUTH_TOKEN="$WEBUI_TOKEN"
else
    export AUTH_TOKEN="hermes2026"
fi

mkdir -p /home/user/.hermes-web-ui
touch "$LOG_FILE"

hermes-web-ui start --port 7860

# --- 5. 容器保活 ---
tail -f "$LOG_FILE"
