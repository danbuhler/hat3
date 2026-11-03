# Changelog

## 0.5.0

- Install the GitHub CLI (`gh`), with its login kept in `/data/gh` and `git` set up to use it for GitHub
- Keep `git config --global` settings, such as your identity, in `/data/.gitconfig`
- Add an `extra_packages` option that installs Debian packages on each start
- Exclude the downloaded T3 Code server from add-on backups

## 0.4.1

- Fix "Provider turn failed" in Claude sessions: set `IS_SANDBOX=1`, because Claude Code refuses T3's permission flags when running as root
- Add a `machine_name` option for the name T3 Code shows for this machine
- Correct the container name in the login instructions (`app_` prefix)

## 0.4.0

- Switch to a Debian base image: the `t3` npm package now downloads a glibc server executable that cannot run on Alpine
- Install Claude Code with the native installer: the `t3` package no longer bundles a Claude binary, which made the Docker build fail
- Remove `node-gyp` and build tools: the server ships a prebuilt `node-pty`
- Correct the install and Claude login instructions

## 0.3.4

- Fix Docker layer cache not invalidating on run.sh changes (COPY config.yaml as cache-buster)

## 0.3.3

- Remove startup diagnostic test (was crashing container) — replaced with simple version log

## 0.3.2

- Fix startup crash: guard diagnostic test against bashio's `set -e` (non-zero exit from test was aborting run.sh)

## 0.3.1

- Use SDK-bundled Claude binary instead of separate curl install — ensures exact version alignment between SDK (0.2.141) and CLI (2.1.141), fixing `setPermissionMode` exit code 1
- Add startup diagnostic: tests Claude in agent-SDK mode and logs results

## 0.3.0

- Switch Claude Code from npm JS wrapper to native binary installer — fixes agent SDK crash (`setPermissionMode` exit code 1)
- Persist `/root/.claude.json` across container rebuilds (symlinked to `/data`)

## 0.2.0

- Switch from API key to Claude OAuth login (no API keys needed)
- Add auth status check on startup with instructions if not logged in
- Enable `stdin` for container shell access

## 0.1.0

- Initial release
- Runs t3 serve on port 3773 with Claude Code pre-installed
- Pairing token printed to add-on logs on startup
- Persistent storage for t3 data and Claude credentials
- Full HA management access (config, API, supervisor)
- `ha` helper script for quick API calls
- `CLAUDE.md` template with HA management context
