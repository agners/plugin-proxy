# Home Assistant Proxy Plugin

Supervisor plugin that fronts Home Assistant Core with a reverse proxy, built
on a trimmed [Caddy](https://caddyserver.com/). It owns the HTTP and HTTPS
ports on the host, terminates TLS, and speaks HTTP/1.1, HTTP/2 and HTTP/3 to
clients while forwarding to Core over a Unix socket.

## How it is controlled

Supervisor manages the plugin's lifecycle (install, update, watchdog). Home
Assistant Core owns the configuration: it renders a Caddy JSON config from
its HTTP settings and pushes it to Caddy's admin API over a Unix socket.

| Socket (inside the container) | Who listens | Who connects |
|---|---|---|
| `/run/supervisor/proxy/proxy.sock` | Caddy admin API | Core |
| `/run/supervisor/core/core.sock` | Core | Caddy (reverse proxy upstream) |

Caddy starts from `/etc/caddy/initial.json`, which only opens the admin
socket, and resumes the last pushed config from `/data` on restart so it
keeps serving while Core is still starting.

## Building

```sh
docker buildx build --platform linux/amd64 \
  --label io.hass.version=2026.11.0 \
  -t ghcr.io/home-assistant/amd64-hassio-proxy:2026.11.0 .
```

The Supervisor reads the installed version from the `io.hass.version` label
and expects an image tag with that version. CI sets the label; a local build
must pass it, otherwise the label of the base image is inherited.

The Caddy binary is built from `caddy/main.go` with only the modules the
plugin needs; see the imports there to add one.
