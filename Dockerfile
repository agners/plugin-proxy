FROM golang:1.26.5-alpine3.24 AS builder

WORKDIR /usr/src
ARG TARGETARCH

# Build a trimmed Caddy with only the modules the plugin uses
COPY caddy caddy
RUN \
    set -x \
    && if [ -z "${TARGETARCH}" ]; then \
            echo "TARGETARCH is not set, please use Docker BuildKit for the build." && exit 1; \
        fi \
    && case "${TARGETARCH}" in \
            amd64|arm64) ;; \
            *) echo "Unsupported TARGETARCH: ${TARGETARCH}" && exit 1 ;; \
        esac \
    && cd caddy \
    && go mod tidy \
    && CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" \
        go build -trimpath -tags nobadger,nomysql,nopgx \
            -ldflags "-s -w" -o /usr/bin/caddy .

# Base image updated by Renovate, update versionCompatibility on Alpine base bump
FROM ghcr.io/home-assistant/base:3.24-2026.10.3@sha256:880016115f356afc814398e17ba68a7ee66dfc1b4eaef09755ea2c9fa18ea481

# Everything in this image runs s6-supervised and is stopped gracefully
# by s6-rc: skip the blind SIGTERM-to-SIGKILL grace sleep at shutdown.
ENV S6_KILL_GRACETIME=0 \
    XDG_CONFIG_HOME=/data \
    XDG_DATA_HOME=/data

WORKDIR /data
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY rootfs /

LABEL \
    io.hass.type="proxy" \
    org.opencontainers.image.title="Home Assistant Proxy Plugin" \
    org.opencontainers.image.description="Home Assistant Supervisor plugin for the HTTP reverse proxy" \
    org.opencontainers.image.authors="The Home Assistant Authors" \
    org.opencontainers.image.url="https://www.home-assistant.io/" \
    org.opencontainers.image.documentation="https://www.home-assistant.io/docs/" \
    org.opencontainers.image.licenses="Apache License 2.0"
