# --------------------------------------------------------------------------
# Dockerfile: 通用开发环境 (Universal Development Environment)
#
# 这个 Dockerfile 构建了一个基于 Ubuntu 22.04 的强大环境。
# 它使用多阶段构建来编译和安装最新的 Python，同时包含 1Panel、
# MySQL、SSH 和 Supervisor 等服务，以提供一个功能全面的容器。
# --------------------------------------------------------------------------

# ==========================================================================
# 阶段 1: Python 来源 (python_source)
# 职责: 提供一个预编译的、与最终镜像 (Ubuntu 22.04) 兼容的 Python 版本。
#       使用官方 python:3.12-jammy 镜像可以完全避免耗时的编译过程。
# --------------------------------------------------------------------------
# FROM ubuntu/python:3.10-22.04_stable AS python_source


# ==========================================================================
# 阶段 2: 最终镜像阶段 (final)
# 职责: 构建最终的、功能完整的镜像。
# --------------------------------------------------------------------------

# --- 基础镜像设置 ---
FROM boxcutter/python:3.11-slim-jammy

# 设置环境变量，包括非交互式安装、时区和 SSH 凭据。
# GEMINI_BALANCE_ENV_TYPE=docker/claw
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    SSH_USER=ubuntu \
    SSH_PASSWORD=ubuntu!23 \
    GEMINI_BALANCE_ENV_TYPE=docker

# 定义 1Panel 版本参数。
ARG PANELVER=v1.10.32-lts

# 复制自定义的入口点脚本和重启脚本。
COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot

# --- 核心依赖和服务安装 ---
# 将所有安装和配置步骤合并到一个 RUN 指令中，以减少镜像层数和大小。
RUN apt-get update && \
    # --- 系统和目录配置 (前置) ---
    # 先创建 mysql 用户和组，避免与 mysql-server 安装冲突
    groupadd -r mysql && useradd -r -g mysql mysql && \
    # 安装运行时所需的依赖
    apt-get install -y --no-install-recommends \
    tzdata \
    openssh-server \
    sudo \
    curl \
    ca-certificates \
    supervisor \
    cron \
    unzip \
    python3.11-venv \
    iproute2 && \
    # 配置 MySQL 非交互式安装
    echo mysql-community-server mysql-community-server/root-pass password '' | debconf-set-selections && \
    echo mysql-community-server mysql-community-server/re-root-pass password '' | debconf-set-selections && \
    apt-get install -y mysql-server && \
    # --- 清理 ---
    # 清理 APT 缓存，减小最终镜像体积
    apt-get clean && \
    # 清理数据库文件，因为要放到持久卷中
    mkdir -p /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/lib/mysql-upgrade && \
    rm -rf /var/lib/apt/lists/* && \
    # --- 目录和权限配置 ---
    mkdir -p /var/run/sshd /var/run/mysqld /home/hr0530/1panel /home/hr0530/mysql /home/hr0530/apps /var/log/supervisor /var/log/mysql && \
    chown -R mysql:mysql /var/log/mysql /home/hr0530/mysql && \
    chmod 1777 /var/run/mysqld && \
    chmod +x /entrypoint.sh /usr/local/sbin/reboot && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# # --- 1Panel 安装 ---
# WORKDIR /home/hr0530/apps/1panel

# # 复制自定义的安装脚本。
# COPY install.override.sh .
# COPY update_app_version.sh .

# # 下载、解压并运行 1Panel 的安装脚本。
# RUN INSTALL_MODE="stable" && \
#     ARCH=$(dpkg --print-architecture) && \
#     if [ "$ARCH" = "armhf" ]; then ARCH="armv7"; fi && \
#     if [ "$ARCH" = "ppc64el" ]; then ARCH="ppc64le"; fi && \
#     PACKAGE_FILE_NAME="1panel-${PANELVER}-linux-${ARCH}.tar.gz" && \
#     PACKAGE_DOWNLOAD_URL="https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/${PANELVER}/release/${PACKAGE_FILE_NAME}" && \
#     echo "Downloading ${PACKAGE_DOWNLOAD_URL}" && \
#     curl -sSL -o ${PACKAGE_FILE_NAME} "$PACKAGE_DOWNLOAD_URL" && \
#     tar zxvf ${PACKAGE_FILE_NAME} --strip-components 1 && \
#     # 使用自定义的安装脚本替换默认脚本。
#     rm -f /home/hr0530/apps/1panel/install.sh && \
#     mv -f /home/hr0530/apps/1panel/install.override.sh /home/hr0530/apps/1panel/install.sh && \
#     chmod +x /home/hr0530/apps/1panel/install.sh /home/hr0530/apps/1panel/update_app_version.sh && \
#     # 执行安装脚本。
#     bash /home/hr0530/apps/1panel/install.sh --install-dir /home/hr0530/1panel && \
#     # 移动更新脚本到最终位置。
#     mv /home/hr0530/apps/1panel/update_app_version.sh /home/hr0530/1panel/ && \
#     # 清理安装文件。
#     rm -rf /home/hr0530/apps/1panel/*

# --- 最终配置 ---
WORKDIR /root

# 从构建阶段复制编译好的 Python。
# 从 python_source 阶段复制预编译的 Python。
# 官方镜像将 Python 安装在 /usr/local 目录中。
# COPY --from=python_source /usr/bin/python* /usr/bin/python*

# 设置环境变量，以便在终端中直接使用 'python3.10' 命令。
# ENV PATH="/usr/local/python3.10/bin:$PATH"

# 安装 Python 3.10 的依赖包和 pip 包。
# --- Supervisor 配置 ---
# 复制 Supervisor 配置文件。日志目录已在核心安装步骤中创建。
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 复制并设置自定义启动脚本的权限。
COPY start-1panel.sh /usr/local/bin/start-1panel.sh
COPY start-gemini-balance.sh /usr/local/bin/start-gemini-balance.sh
COPY init-mysql.sh /usr/local/bin/init-mysql.sh
RUN chmod +x /usr/local/bin/start-1panel.sh \
    /usr/local/bin/start-gemini-balance.sh \
    /usr/local/bin/init-mysql.sh

# 声明单个持久化卷的挂载点。
VOLUME /home/hr0530

# 暴露服务端口。
EXPOSE 10086 22 8000

# 复制 init.sql 文件来初始化数据库
COPY init.sql /tmp/init.sql

# 设置容器启动时执行的入口点命令。
ENTRYPOINT ["/entrypoint.sh"]

# 使用 Supervisor 管理服务
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]