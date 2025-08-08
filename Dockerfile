# --------------------------------------------------------------------------
# Dockerfile: 通用开发环境 (Universal Development Environment)
#
# 这个 Dockerfile 构建了一个基于 Ubuntu 22.04 的强大环境。
# 它使用多阶段构建来编译和安装最新的 Python，同时包含 1Panel、
# MySQL、SSH 和 Supervisor 等服务，以提供一个功能全面的容器。
# --------------------------------------------------------------------------

# ==========================================================================
# 阶段 1: 构建阶段 (builder)
# 职责: 编译和安装特定版本的 Python。
# --------------------------------------------------------------------------
FROM ubuntu:22.04 as builder

# 安装所有编译 Python 所需的构建依赖。
# 这些依赖只存在于此阶段，不会被带入最终镜像，以保持最终镜像的精简。
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    tk-dev && \
    rm -rf /var/lib/apt/lists/*

# 下载、解压并配置 Python 源代码。
RUN wget https://www.python.org/ftp/python/3.12.11/Python-3.12.11.tgz && \
    tar xvf Python-3.12.11.tgz

WORKDIR /Python-3.12.11

# 编译并将 Python 安装到指定目录，以便在下一阶段复制。
RUN ./configure --prefix=/usr/local/python3.12 && \
    make && \
    make install


# ==========================================================================
# 阶段 2: 最终镜像阶段 (final)
# 职责: 构建最终的、功能完整的镜像。
# --------------------------------------------------------------------------

# --- 基础镜像设置 ---
FROM ubuntu:22.04

# 设置环境变量，包括非交互式安装、时区和 SSH 凭据。
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    SSH_USER=ubuntu \
    SSH_PASSWORD=ubuntu!23

# 定义 1Panel 版本参数。
ARG PANELVER=v1.10.32-lts

# 复制自定义的入口点脚本和重启脚本。
COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot

# --- 核心依赖和服务安装 ---
# 安装核心系统工具、SSH 服务、Supervisor 和 MySQL 服务。
RUN groupadd -r mysql && useradd -r -g mysql mysql && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    tzdata \
    openssh-server \
    sudo \
    curl \
    ca-certificates \
    wget \
    vim \
    net-tools \
    supervisor \
    cron \
    unzip \
    iputils-ping \
    telnet \
    git \
    iproute2 && \
    # 配置 MySQL 非交互式安装，避免在构建过程中停顿。
    echo mysql-community-server mysql-community-server/root-pass password '' | debconf-set-selections && \
    echo mysql-community-server mysql-community-server/re-root-pass password '' | debconf-set-selections && \
    apt-get install -y mysql-server && \
    # 清理 APT 缓存以减小镜像体积。
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # 创建服务所需的目录，并设置权限。
    mkdir -p /var/run/sshd /var/run/mysqld /home/hr0530/1panel && \
    chmod 1777 /var/run/mysqld && \
    chmod +x /entrypoint.sh /usr/local/sbin/reboot && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone


# --- 1Panel 安装 ---
WORKDIR /home/hr0530/apps/1panel

# 复制自定义的安装脚本。
COPY install.override.sh .
COPY update_app_version.sh .

# 下载、解压并运行 1Panel 的安装脚本。
RUN INSTALL_MODE="stable" && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "armhf" ]; then ARCH="armv7"; fi && \
    if [ "$ARCH" = "ppc64el" ]; then ARCH="ppc64le"; fi && \
    PACKAGE_FILE_NAME="1panel-${PANELVER}-linux-${ARCH}.tar.gz" && \
    PACKAGE_DOWNLOAD_URL="https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/${PANELVER}/release/${PACKAGE_FILE_NAME}" && \
    echo "Downloading ${PACKAGE_DOWNLOAD_URL}" && \
    curl -sSL -o ${PACKAGE_FILE_NAME} "$PACKAGE_DOWNLOAD_URL" && \
    tar zxvf ${PACKAGE_FILE_NAME} --strip-components 1 && \
    # 使用自定义的安装脚本替换默认脚本。
    rm -f /home/hr0530/apps/1panel/install.sh && \
    mv -f /home/hr0530/apps/1panel/install.override.sh /home/hr0530/apps/1panel/install.sh && \
    chmod +x /home/hr0530/apps/1panel/install.sh /home/hr0530/apps/1panel/update_app_version.sh && \
    # 执行安装脚本。
    bash /home/hr0530/apps/1panel/install.sh --install-dir /home/hr0530/1panel && \
    # 移动更新脚本到最终位置。
    mv /home/hr0530/apps/1panel/update_app_version.sh /home/hr0530/1panel/ && \
    # 清理安装文件。
    rm -rf /home/hr0530/apps/1panel/*

# --- 最终配置 ---
WORKDIR /root

# 从构建阶段复制编译好的 Python。
COPY --from=builder /usr/local/python3.12 /usr/local/python3.12

# 设置环境变量，以便在终端中直接使用 'python3.12' 命令。
ENV PATH="/usr/local/python3.12/bin:$PATH"

# 复制并设置自定义启动脚本的权限。
COPY start-1panel.sh /usr/local/bin/start-1panel.sh
COPY start-mysql.sh /usr/local/bin/start-mysql.sh
RUN chmod +x /usr/local/bin/start-1panel.sh /usr/local/bin/start-mysql.sh

# 声明单个持久化卷的挂载点。
VOLUME /home/hr0530

# 暴露服务端口。
EXPOSE 10086 22

# 设置容器启动时执行的入口点命令。
ENTRYPOINT ["/entrypoint.sh"]

# 设置入口点执行的默认命令。
CMD ["/usr/sbin/sshd", "-D"]
