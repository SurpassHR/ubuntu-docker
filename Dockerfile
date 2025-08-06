#
# Dockerfile for a Universal Development and CI/CD Environment
#
# This Dockerfile sets up a comprehensive environment based on Ubuntu 22.04,
# including Docker-in-Docker (dind), Docker Compose, and a standard toolchain.
#

# --- Base Image ---
# Use Ubuntu 22.04 as the base for a stable and widely supported environment.
FROM ubuntu:22.04

# --- Environment Variables ---
# Set DEBIAN_FRONTEND to noninteractive to prevent prompts during package installation,
# enabling fully automated builds.
ENV DEBIAN_FRONTEND=noninteractive

# --- Layer 1: Core Toolchain and Dependencies ---
# Install essential tools and dependencies for dind. This layer is separated
# to leverage Docker's build cache, as these packages change infrequently.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # For general use and scripting
        git \
        curl \
        wget \
        vim \
        sudo \
        unzip \
        jq \
        procps \
        # For networking inspection
        net-tools \
        # Dependencies for Docker installation
        ca-certificates \
        gnupg && \
    # Clean up apt cache to reduce image size
    rm -rf /var/lib/apt/lists/*

# --- Layer 2: Docker Engine (dind) Installation ---
# Install the latest stable version of Docker Engine following the official guide.
# This allows running Docker commands inside the container.
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin && \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*

# --- Layer 3: Docker Compose Installation ---
# Install the latest version of Docker Compose V2.
# The version is dynamically fetched to ensure it's always up-to-date.
RUN DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name) && \
    DOCKER_CLI_PLUGINS_DIR="/usr/local/lib/docker/cli-plugins" && \
    mkdir -p ${DOCKER_CLI_PLUGINS_DIR} && \
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o ${DOCKER_CLI_PLUGINS_DIR}/docker-compose && \
    chmod +x ${DOCKER_CLI_PLUGINS_DIR}/docker-compose

# --- Layer 4: Pre-provision Code ---
# Create a workspace directory and clone specified git repositories.
# This step is placed later in the build process because code changes more
# frequently than the base environment.
RUN mkdir -p /apps && \
    git clone https://github.com/okxlin/docker-1panel.git /apps/docker-1panel && \
    git clone https://github.com/SurpassHR/gemini-balance.git /apps/gemini-balance

# --- Layer 5: Final Configuration ---
# Set the default working directory for the container.
WORKDIR /apps

# Copy the entrypoint script and make it executable.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to our custom script.
ENTRYPOINT ["entrypoint.sh"]

# Provide a default command. When the container starts, it will launch a bash shell,
# allowing for interactive use.
CMD ["bash"]