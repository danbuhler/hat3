# T3 Code — Home Assistant Add-on Repository

Fork of [cinderblock/hat3](https://github.com/cinderblock/hat3), moved to a Debian base because the current `t3` server is a glibc executable that cannot run on the original Alpine image.

Home Assistant add-on that runs [T3 Code](https://github.com/pingdotgg/t3code), a web GUI for AI coding agents (Claude, Codex, and more).

## Installation

1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**
2. Click the three-dot menu (top right) > **Repositories**
3. Paste this repository URL and click **Add**:
   ```
   https://github.com/danbuhler/hat3
   ```
4. Find **T3 Code** in the store and click **Install**
5. Start the add-on. The first start downloads the T3 Code server (about 360 MB unpacked), so give it a minute or two
6. Check the **Log** tab for the pairing token and open `http://<ha-ip>:3773/pair#token=<token>`. For HTTPS and access away from home, set up [remote access with Tailscale](#remote-access-with-tailscale) (recommended)
7. Log in to Claude with your subscription — see [Claude Authentication](./t3code/DOCS.md#claude-authentication). No API key is needed

## Add-ons

### [T3 Code](./t3code)

Runs `t3 serve` on port 3773 with Claude Code pre-installed. Prints a one-time pairing token to the logs on startup. For HTTPS access from your devices without opening a LAN port, see [Remote access with Tailscale](#remote-access-with-tailscale).

## Pairing After First Start

The pairing URL (with token) appears in the add-on logs on every fresh start. If you need a new token later:

1. Open the add-on **Log** tab
2. Look for the line: `Pairing URL: http://...`
3. If the token has expired, restart the add-on to generate a new one

You can also use `t3 auth pairing create` from within the container terminal.

The pairing URL in the log uses the container's internal Docker address (for example `http://172.30.33.5:3773/pair#token=...`), which other devices can't open. Keep the token from the end of that URL and put it after the address you actually use, as shown below.

## Remote access with Tailscale

T3 Code listens on port 3773 inside the add-on container. By default the add-on publishes it as port 3773 on the Home Assistant host, so `http://<ha-ip>:3773` works on your LAN, but only over plain HTTP. Tailscale is the recommended way to connect: you get HTTPS, access from anywhere in your tailnet, and you can then close the LAN port. There is no ingress, so T3 Code doesn't appear in the Home Assistant sidebar.

### Find the add-on's hostname

On Home Assistant's internal network the add-on is reachable as `<repo-hash>-t3code`. When the add-on is installed from `https://github.com/danbuhler/hat3`, that is `1be93311-t3code`. The prefix depends on how the repository was added, so check yours on the add-on's **Info** page (shown as **Hostname**), or from a shell on the host:

```bash
docker ps --format '{{.Names}}' | grep t3code                               # e.g. app_1be93311_t3code
docker inspect -f '{{.Config.Hostname}}' app_1be93311_t3code                 # e.g. 1be93311-t3code
```

### Option A: Tailscale (recommended)

Only devices in your tailnet can reach it, it gets a valid HTTPS certificate, and you can close the port on your LAN.

1. Install the **Tailscale** add-on from Home Assistant Community Add-ons and log in.
2. In the [Tailscale admin console](https://login.tailscale.com/admin/dns), under **DNS**, turn on **MagicDNS** and **HTTPS Certificates**.
3. From an SSH/terminal add-on with Docker access (for the Advanced SSH & Web Terminal add-on, turn **Protection mode** off), find the Tailscale container name:
   ```bash
   docker ps --format '{{.Names}}' | grep tailscale
   ```
   Newer Home Assistant versions name it `app_a0d7b954_tailscale`; older ones use `addon_a0d7b954_tailscale`.
4. Tell Tailscale to serve T3 Code on port 3773, using the container name from step 3 and the hostname from above:
   ```bash
   docker exec app_a0d7b954_tailscale /opt/tailscale serve --bg --https=3773 http://1be93311-t3code:3773
   ```
5. Open `https://<ha-machine>.<tailnet>.ts.net:3773/pair#token=<token>`, with the token from the T3 Code add-on log. Don't open the URL the log prints. The first load can take a few seconds while the certificate is issued.
6. Recommended: close the LAN port. Go to **Settings > Add-ons > T3 Code > Configuration > Network**, clear the 3773/tcp field, save, and restart the add-on. Tailscale reaches the add-on over the internal network, so it keeps working.

Notes:

- The Serve rule survives restarts. The Tailscale add-on resets the Serve config only once, on its first start.
- Point Serve at the add-on's hostname, not `http://127.0.0.1:3773`. `127.0.0.1` inside the Tailscale container only reaches T3 Code while the port is also published on the host, so it breaks once you close the LAN port.
- To remove the rule:
  ```bash
  docker exec app_a0d7b954_tailscale /opt/tailscale serve --https=3773 off
  ```

### Option B: LAN port

This is the default: the add-on publishes 3773/tcp as host port 3773. To change the port, or to restore it after clearing it, go to **Settings > Add-ons > T3 Code > Configuration > Network**, set 3773/tcp to a host port, save, and restart. Then open `http://<ha-ip>:<port>/pair#token=<token>`. This is plain HTTP and open to your whole LAN.

## Troubleshooting

- **Page won't load, or the pairing URL shows a `172.30.x.x` address**: that is the internal Docker address. Use `http://<ha-ip>:3773` (check the port wasn't cleared under **Network**) or Tailscale as described in [Remote access with Tailscale](#remote-access-with-tailscale), and keep only the token from the logged URL.
- **`Background Git fetch failed (authentication_failed)` or `No GitHub credential` in the log**: GitHub isn't logged in inside the container. The add-on includes the GitHub CLI and sets it as git's credential helper for `https://github.com`. Log in once from a shell on the host:
  ```bash
  docker exec -it app_1be93311_t3code gh auth login
  ```
  To use a personal access token instead, pipe it in:
  ```bash
  echo "$GITHUB_TOKEN" | docker exec -i app_1be93311_t3code gh auth login --with-token
  ```
  The login is stored in `/data/gh` and survives restarts and updates. The credential helper only covers HTTPS remotes, so change any `git@github.com:` remotes to `https://github.com/...`. See [GitHub CLI](./t3code/DOCS.md#github-cli).
