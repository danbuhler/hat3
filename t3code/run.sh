#!/usr/bin/with-contenv bashio

# Persistent storage for t3 and claude across container rebuilds
mkdir -p /data/t3code /data/.claude

# Symlink Claude config directory so credentials persist
if [ ! -L /root/.claude ]; then
    rm -rf /root/.claude
    ln -s /data/.claude /root/.claude
fi

# Persist .claude.json (settings/state file) across container rebuilds
if [ -f /data/.claude.json ]; then
    ln -sf /data/.claude.json /root/.claude.json
elif [ -f /root/.claude.json ]; then
    mv /root/.claude.json /data/.claude.json
    ln -sf /data/.claude.json /root/.claude.json
else
    touch /data/.claude.json
    ln -sf /data/.claude.json /root/.claude.json
fi

export T3CODE_HOME=/data/t3code

# Override the Docker hostname (HA sets it to the full slug with repo hash)
hostname t3code 2>/dev/null || true

# T3 reads its display name from here once, when the server starts
if bashio::config.has_value 'machine_name'; then
    machine_name="$(bashio::config 'machine_name')"
    printf 'PRETTY_HOSTNAME="%s"\n' "${machine_name//\"/}" > /etc/machine-info
fi

# Containers are recreated on restart and update, so install these on each start.
# Install one at a time so a bad name or a network failure can't block the rest.
if bashio::config.has_value 'extra_packages'; then
    apt_updated=false
    for package in $(bashio::config 'extra_packages'); do
        if dpkg -s "$package" >/dev/null 2>&1; then
            continue
        fi
        if [ "$apt_updated" = false ]; then
            bashio::log.info "Updating package lists for extra packages..."
            timeout 300 apt-get update -qq >/dev/null 2>&1 || \
                bashio::log.warning "Could not update package lists"
            apt_updated=true
        fi
        bashio::log.info "Installing extra package: ${package}"
        if ! DEBIAN_FRONTEND=noninteractive timeout 600 \
            apt-get install -y -qq --no-install-recommends "$package" >/dev/null 2>&1; then
            bashio::log.warning "Could not install extra package: ${package}"
        fi
    done
fi

# Check Claude auth status and guide user if not logged in
if claude auth status 2>/dev/null | grep -q '"loggedIn"[[:space:]]*:[[:space:]]*true'; then
    bashio::log.info "Claude is authenticated"
else
    bashio::log.warning "=========================================="
    bashio::log.warning "  Claude is NOT authenticated."
    bashio::log.warning "  To log in, run this from a shell on the HA host:"
    bashio::log.warning ""
    bashio::log.warning "    docker exec -it app_1be93311_t3code claude auth login"
    bashio::log.warning ""
    bashio::log.warning "  (Use app_local_t3code for a local add-on install.)"
    bashio::log.warning ""
    bashio::log.warning "  Follow the OAuth prompts, then restart"
    bashio::log.warning "  this add-on."
    bashio::log.warning "=========================================="
fi

bashio::log.info "Claude version: $(claude --version 2>/dev/null || echo 'not found')"

# Install CLAUDE.md into /config if not already present
if [ ! -f /config/CLAUDE.md ]; then
    bashio::log.info "Installing CLAUDE.md into HA config directory"
    cp /etc/t3code/CLAUDE.md /config/CLAUDE.md
fi

# Correct the config check command in CLAUDE.md files installed by older versions
if grep -q 'ha /core/api/config/core/check\([^_]\|$\)' /config/CLAUDE.md; then
    bashio::log.info "Correcting the config check command in /config/CLAUDE.md"
    sed -i 's#ha /core/api/config/core/check\([^_]\|$\)#ha /core/api/config/core/check_config -X POST\1#' /config/CLAUDE.md
fi

# Give the config project a Home Assistant icon, without replacing one you added
if [ ! -f /config/favicon.svg ]; then
    cp /etc/t3code/favicon.svg /config/favicon.svg
fi

# Add /config as a T3 project once, so removing it in T3 sticks. This also
# downloads the T3 server on the first start of each version.
if [ ! -f /data/t3code/.config-project-added ]; then
    bashio::log.info "Adding /config as a T3 Code project..."
    if project_output="$(t3 project add /config --title "Home Assistant" 2>&1)" || \
        grep -q 'ProjectAlreadyExistsError' <<< "$project_output"; then
        touch /data/t3code/.config-project-added
    else
        bashio::log.warning "Could not add /config as a T3 Code project"
        bashio::log.warning "$(tail -n 3 <<< "$project_output")"
    fi
fi

bashio::log.info "Starting T3 Code server on port 3773..."
bashio::log.info "The first start of each version downloads the server, which can take a few minutes"
bashio::log.info "Working directory: /config"
bashio::log.info "Check the logs below for the pairing token/URL"

cd /config
exec t3 serve --host 0.0.0.0 --port 3773
