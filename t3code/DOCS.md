# T3 Code

T3 Code is a web GUI for AI coding agents. It supports Claude (via Claude Code), Codex, OpenCode, and more.

This add-on runs T3 Code in headless serve mode with full Home Assistant management access — Claude Code can edit configs, call services, manage automations, and control your HA instance.

## Setup

1. **Start the add-on** and check the **Log** tab for the pairing URL.
2. **Pair your browser**: Copy the `Pairing URL:` from the logs and open it in your browser.
3. **Authenticate Claude**: See [Claude Authentication](#claude-authentication). Credentials persist across restarts.
4. You're ready — create a Claude session in the T3 web UI.

## Machine Name

Set **Machine name** in the **Configuration** tab to change the name T3 Code shows for this machine, then restart the add-on.

Clients that are already paired keep showing the old name. To update one, generate a new token and pair it again using the same URL. If the old name stays, use **Remove from this device** under **Settings > Environments** and then pair again, which also clears that client's saved pairing and cached threads.

## Extra Packages

List Debian package names under **Extra packages** in the **Configuration** tab, then restart the add-on. They are installed on each start, because the container is recreated on restarts and updates, so long lists slow startup. A package that fails to install is logged as a warning and the add-on still starts.

## Port

The web interface runs on port **3773** by default. Access it at `http://<your-ha-ip>:3773` after pairing.

## What Claude Can Do

This add-on gives Claude Code full admin access to your HA instance:

- **Edit configuration** — `configuration.yaml`, automations, scripts, scenes, and all config files
- **Call services** — turn lights on/off, trigger automations, control any entity
- **Read state** — query entity states, check sensor values, view device info
- **Manage system** — restart HA, reload configs, view supervisor/host info, manage add-ons and backups
- **Access files** — read/write `/config`, `/share`, `/media`; read `/ssl`, `/addons`

A `CLAUDE.md` is automatically installed in `/config` on first start, giving Claude Code context about available APIs and HA patterns.

A `ha` helper script is available inside the container for quick API calls.

## Claude Authentication

Claude uses OAuth — no API keys needed. Authenticate once and credentials persist in `/data/.claude` across add-on updates and restarts.

**To authenticate (first time or after token expiry):** run this from a shell on the HA host. The `ha` CLI has no way to run a command inside an add-on, so this needs `docker`:

```bash
docker exec -it app_1be93311_t3code claude auth login
```

Follow the prompts: visit the URL, authorize, paste the code back. Then restart the add-on.

The container name comes from the repository URL, so `1be93311` is specific to `https://github.com/danbuhler/hat3`. A local add-on install uses `app_local_t3code` instead. Older Home Assistant versions use an `addon_` prefix, so run `docker ps | grep t3code` if the name is not found.

**To check auth status:**

```bash
docker exec app_1be93311_t3code claude auth status
```

## GitHub CLI

`gh` is installed. To log in, run this from a shell on the HA host:

```bash
docker exec -it app_1be93311_t3code gh auth login
```

The login is stored in `/data/gh`, so it survives restarts and updates, and is included in add-on backups. Once logged in, `git` uses it for GitHub automatically. Settings made with `git config --global`, such as your name and email, are kept in `/data/.gitconfig`. Claude sessions in this add-on can use the same GitHub access, so consider a token limited to the repositories it needs.

## Pairing Tokens

The T3 pairing token is printed to logs on startup. If you need a new one:

- **Restart** the add-on — a fresh token is printed each time.

## Data Persistence

- **T3 data** (sessions, auth, projects) is stored in `/data/t3code` and survives add-on updates.
- **Claude credentials** are stored in `/data/.claude`.
- **GitHub CLI login** is stored in `/data/gh`.
- **Backups** leave out the downloaded T3 Code server (`/data/t3code/runtime`), which is downloaded again on the next start after a restore.
- **HA config** is at `/config` (the real HA config directory, read/write).
- **Shared files** live in `/share`, accessible from other add-ons and via Samba/SSH.

## Providers

T3 Code supports multiple AI coding agent backends:

- **Claude** — authenticate via OAuth (see above)
- **Codex** — configure via the T3 web UI after pairing
- **OpenCode** — configure via the T3 web UI after pairing

## Troubleshooting

- **No pairing URL in logs**: The first start of each version downloads the T3 Code server, which can take a few minutes. After that, t3 initializes in 10-20 seconds. If still missing, check for errors above the expected output.
- **Claude provider not working**: Check auth status (see above). If expired, re-authenticate and restart the add-on.
- **Port conflict**: If port 3773 is already in use, change the host port mapping in the add-on Network configuration.
- **Config changes not taking effect**: Use the T3 web UI to ask Claude to validate and reload the config, or restart HA from the Supervisor panel.
