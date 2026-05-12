FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HOME=/home/user \
    PATH=/home/user/.local/bin:/home/user/.npm-global/bin:/home/user/.cargo/bin:/home/user/agent/.venv/bin:$PATH

# 一次性配齐所有系统底层库与工具链
RUN apt-get update && apt-get install -y \
    curl git python3.11 python3-pip build-essential lsof \
    ffmpeg ripgrep imagemagick poppler-utils tesseract-ocr tesseract-ocr-chi-sim jq zip unzip tar gzip \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
    libxrandr2 libgbm1 libasound2 && \
    curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 user
USER user
WORKDIR /home/user

# 配置 npm 全局路径
RUN mkdir -p /home/user/.npm-global && \
    npm config set prefix '/home/user/.npm-global' && \
    npm install -g npm@latest

# 安装 uv, Agent 核心及 Playwright 浏览器内核
# (已移除 pip install --no-cache-dir huggingface_hub)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    git clone https://github.com/nousresearch/hermes-agent.git /home/user/agent && \
    cd /home/user/agent && \
    uv venv .venv --python 3.11 && \
    . .venv/bin/activate && \
    uv pip install -e ".[all]" playwright && \
    playwright install chromium

# 安装 Web UI
RUN npm install -g hermes-web-ui@latest

RUN mkdir -p /home/user/.hermes

COPY --chown=user:user start.sh /home/user/start.sh
RUN chmod +x /home/user/start.sh

EXPOSE 7860

CMD ["/home/user/start.sh"]
