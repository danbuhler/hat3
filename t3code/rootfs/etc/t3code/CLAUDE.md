# Home Assistant — Claude Code Context

You are running inside a Home Assistant add-on container with full admin access.
Your working directory is `/config` — the HA configuration root.

## Available APIs

The `SUPERVISOR_TOKEN` env var is set automatically. Use the `ha` helper or raw curl.

### `ha` helper script

```bash
# Entity states
ha /core/api/states                                    # all entities
ha /core/api/states/sensor.temperature                 # one entity

# Call services
ha /core/api/services/light/turn_on '{"entity_id":"light.living_room"}'
ha /core/api/services/switch/toggle '{"entity_id":"switch.garage"}'
ha /core/api/services/automation/trigger '{"entity_id":"automation.morning"}'

# Templates
ha /core/api/template '{"template":"{{ states.sensor.temp.state }} {{ state_attr(\"sensor.temp\",\"unit_of_measurement\") }}"}'

# Config validation
ha /core/api/config/core/check_config -X POST

# Supervisor
ha /supervisor/info
ha /host/info
ha /os/info
ha /core/info
ha /addons
ha /backups

# Restart / reload
ha /core/restart -X POST
ha /core/api/services/homeassistant/reload_core_config -X POST
```

### Raw curl (when ha helper isn't enough)

```bash
curl -sSf \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  -H "Content-Type: application/json" \
  "http://supervisor/core/api/states"
```

## Filesystem Layout

| Path | Description | Access |
|------|-------------|--------|
| `/config/` | HA config root (CWD) — configuration.yaml, automations, etc. | read/write |
| `/share/` | Shared between add-ons, accessible via Samba/SSH | read/write |
| `/ssl/` | SSL certificates | read-only |
| `/media/` | Media files | read/write |
| `/backup/` | Backup files | read/write |
| `/addons/` | Other add-on directories | read-only |
| `/data/` | This add-on's persistent data | read/write |

## Editing HA Configuration

Config files are YAML. The main file is `/config/configuration.yaml`. After editing:

```bash
# Validate before reloading
ha /core/api/config/core/check_config -X POST

# Reload specific domains (no restart needed)
ha /core/api/services/automation/reload -X POST
ha /core/api/services/script/reload -X POST
ha /core/api/services/scene/reload -X POST
ha /core/api/services/input_boolean/reload -X POST
ha /core/api/services/input_number/reload -X POST
ha /core/api/services/input_select/reload -X POST
ha /core/api/services/input_text/reload -X POST
ha /core/api/services/input_datetime/reload -X POST
ha /core/api/services/group/reload -X POST
ha /core/api/services/timer/reload -X POST
ha /core/api/services/homeassistant/reload_core_config -X POST

# Full restart (only if reload isn't sufficient)
ha /core/restart -X POST
```

## Config YAML Patterns

### Automations (`/config/automations.yaml`)
```yaml
- id: "unique_id_here"
  alias: "Descriptive Name"
  trigger:
    - platform: state
      entity_id: binary_sensor.motion
      to: "on"
  condition:
    - condition: time
      after: "22:00:00"
      before: "06:00:00"
  action:
    - service: light.turn_on
      target:
        entity_id: light.hallway
      data:
        brightness_pct: 30
```

### Template sensors (`/config/configuration.yaml`)
```yaml
template:
  - sensor:
      - name: "Average Temperature"
        unit_of_measurement: "°F"
        state: >
          {{ (states('sensor.indoor_temp') | float +
              states('sensor.outdoor_temp') | float) / 2 | round(1) }}
```

### Scripts (`/config/scripts.yaml`)
```yaml
morning_routine:
  alias: "Morning Routine"
  sequence:
    - service: light.turn_on
      target:
        area_id: kitchen
    - delay: "00:00:05"
    - service: media_player.play_media
      target:
        entity_id: media_player.kitchen_speaker
      data:
        media_content_id: "https://example.com/news.mp3"
        media_content_type: "music"
```

## Important Notes

- Always run `ha /core/api/config/core/check_config -X POST` before restarting HA after config changes.
- Prefer domain-specific reloads over full restarts.
- Use `!include` to split large configs into separate files.
- Entity IDs use the format `domain.object_id` (e.g., `light.kitchen`, `sensor.temperature`).
- Use `git` to track config changes — this directory is already a good candidate for version control.
