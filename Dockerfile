#
# Dockerfile for a Universal Development Environment with 1Panel
#
# This Dockerfile builds a comprehensive environment based on Ubuntu 22.04.
# It includes Docker-in-Docker, a full 1Panel installation, and uses
# Supervisord to manage background services, providing an interactive shell.
#

# --- Base Image ---
FROM ubuntu:22.04

# --- Environment Variables ---
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    SSH_USER=ubuntu \
    SSH_PASSWORD=ubuntu!23

ARG PANELVER=v1.10.32-lts

COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot

# --- Layer 1: Core Dependencies & Supervisor ---
# Install essential tools, dind dependencies, and Supervisor.
RUN apt-get update; \
    apt-get install -y tzdata openssh-server sudo curl ca-certificates wget vim net-tools supervisor cron unzip iputils-ping telnet git iproute2 mysql-server --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /var/run/sshd /var/log/mysql /var/run/mysqld; \
    chown -R mysql:mysql /var/log/mysql /var/run/mysqld; \
    chmod +x /entrypoint.sh; \
    chmod +x /usr/local/sbin/reboot; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
    echo $TZ > /etc/timezone

# --- Layer 2: 1Panel Installation ---
RUN mkdir -p /home/hr0530/apps && git clone https://github.com/SurpassHR/gemini-balance.git /home/hr0530/apps/gemini-balance
# This layer handles the full installation of 1Panel.
WORKDIR /home/hr0530/apps/1panel

# Copy the necessary installation scripts provided by the user.
COPY install.override.sh .
COPY update_app_version.sh .

# Download and run the 1Panel installer.
RUN INSTALL_MODE="stable" && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "armhf" ]; then ARCH="armv7"; fi && \
    if [ "$ARCH" = "ppc64el" ]; then ARCH="ppc64le"; fi && \
    PACKAGE_FILE_NAME="1panel-${PANELVER}-linux-${ARCH}.tar.gz" && \
    PACKAGE_DOWNLOAD_URL="https://resource.fit2cloud.com/1panel/package/${INSTALL_MODE}/${PANELVER}/release/${PACKAGE_FILE_NAME}" && \
    echo "Downloading ${PACKAGE_DOWNLOAD_URL}" && \
    curl -sSL -o ${PACKAGE_FILE_NAME} "$PACKAGE_DOWNLOAD_URL" && \
    tar zxvf ${PACKAGE_FILE_NAME} --strip-components 1 && \
    # Replace the default install script with the override version
    rm -f /home/hr0530/apps/1panel/install.sh && \
    mv -f /home/hr0530/apps/1panel/install.override.sh /home/hr0530/apps/1panel/install.sh && \
    chmod +x /home/hr0530/apps/1panel/install.sh /home/hr0530/apps/1panel/update_app_version.sh && \
    # Run the installer
    bash /home/hr0530/apps/1panel/install.sh && \
    # Move the version update script to the final location for the startup script to use
    mv /home/hr0530/apps/1panel/update_app_version.sh /opt/1panel/ && \
    # Clean up installation files
    rm -rf /home/hr0530/apps/1panel/*

# --- Layer 3: Final Configuration ---
# Copy custom scripts, set permissions, and define entrypoint.
COPY start-1panel.sh /usr/local/bin/start-1panel.sh

RUN chmod +x /usr/local/bin/start-1panel.sh /entrypoint.sh

# Set the default working directory.
WORKDIR /root

# Expose 1Panel port
EXPOSE 10086 22

# Set the main entrypoint.
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]