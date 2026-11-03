ARG BUILD_FROM
FROM ${BUILD_FROM}

# The t3 server ships as a prebuilt glibc executable, so this add-on needs a
# Debian base (see build.yaml); it cannot start on Alpine/musl.
# Debian trixie's Node.js satisfies the t3 launcher's >=20.11 requirement.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nodejs \
        npm \
        python3 \
        git \
        curl \
        ca-certificates \
        bash \
        jq \
        openssh-client && \
    rm -rf /var/lib/apt/lists/*

# GitHub CLI from its official apt repository. Keep its login on persistent
# storage and let git use it for GitHub, since /root does not survive updates.
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/* && \
    git config --system credential.https://github.com.helper '!gh auth git-credential'
ENV GH_CONFIG_DIR=/data/gh

# Keep git identity and other global settings on persistent storage too
ENV GIT_CONFIG_GLOBAL=/data/.gitconfig

# t3 is a small launcher. On first run it downloads the server for this
# platform into $T3CODE_HOME, which run.sh keeps on persistent storage.
RUN npm install -g t3

# The t3 package no longer bundles a Claude binary, so use the native installer.
ENV PATH="/root/.local/bin:${PATH}"
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    claude --version

# Add-ons run as root, and Claude Code refuses T3's permission flags as root
# unless it is told it is running in a sandbox.
ENV IS_SANDBOX=1

# Copy rootfs overlay (helper scripts, CLAUDE.md template)
COPY rootfs /

# config.yaml is copied to bust Docker layer cache when version changes
COPY config.yaml /tmp/addon-config.yaml
COPY run.sh /
RUN chmod a+x /run.sh /usr/local/bin/ha

CMD ["/run.sh"]
