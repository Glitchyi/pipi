# pipi system inventory

Snapshot date: 2026-05-29 IST.

## Host

- Hostname: `pipi`
- User: `glitchy`
- Architecture: `aarch64`
- Kernel observed: `6.12.75+rpt-rpi-2712`
- Main project root: `/home/glitchy`

## Docker Compose Projects

| Project | Path | Source repo | Public ports | Localhost ports | Secret/state required |
| --- | --- | --- | --- | --- | --- |
| `ats` | `/home/glitchy/ATS` | `git@github.com:Glitchyi/ATS.git` | `3000 -> 3000` | none | `/home/glitchy/ATS/.env` |
| `blog` | `/home/glitchy/blog` | `git@github.com:Glitchyi/blog.git` | `3002 -> 80`, `3003 -> 8080` | none | `/home/glitchy/blog/.env`, `/home/glitchy/.docker/config.json` |
| `observing` | `/home/glitchy/observing` | `git@github.com:Glitchyi/observing.git` | `3030 -> 3000` | `9090`, `3100`, `3200`, `12345`, `4317`, `4318` | `/home/glitchy/observing/.env`; optional Docker volumes |
| `openclaw` | `/home/glitchy/openclaw` | `https://github.com/openclaw/openclaw.git` | `18789`, `18790` | none | `/home/glitchy/openclaw/.env`, `/home/glitchy/.openclaw`, `/home/glitchy/.openclaw-auth-profile-secrets` |
| `monke-proxy` | `/home/glitchy/monke-proxy` | `git@github.com:Glitchyi/monke-proxy.git` | none | `8080 -> 8080` | `/home/glitchy/monke-proxy/.env` |

## Cloudflare Tunnel Targets

You said Cloudflare Tunnel will be configured separately. Use these local service targets:

| Service | Target |
| --- | --- |
| `monke-proxy` | `http://127.0.0.1:8080` |
| Grafana | `http://127.0.0.1:3030` or `http://localhost:3030` |
| ATS | `http://127.0.0.1:3000` |
| blog | `http://127.0.0.1:3002` |
| OpenClaw gateway | `http://127.0.0.1:18789` |

## Observability Volumes

These Docker volumes hold runtime observability data. They are not needed to recreate the stack, but back them up if historical dashboards, metrics, logs, or traces matter.

- `observing_grafana-data`
- `observing_prometheus-data`
- `observing_loki-data`
- `observing_tempo-data`
- `observing_alloy-data`

## K3s

- Installed version observed: `v1.35.4+k3s1`
- Service: `k3s`
- Runtime: bundled `containerd`
- Default components observed: `traefik`, `coredns`, `metrics-server`, `local-path-provisioner`
- API listener: `6443/tcp`
- Supervisor/internal listener: `127.0.0.1:6444`
- Flannel VXLAN: `8472/udp`

The current kubeconfig on the live host is `/etc/rancher/k3s/k3s.yaml`. It is a secret and must not be committed.
