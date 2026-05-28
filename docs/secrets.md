# Secret and state backup checklist

Do not commit these files or values. Store them in a password manager, Ansible Vault, or encrypted offline backup.

## Required for services to come back

| Item | Why it matters |
| --- | --- |
| `/home/glitchy/ATS/.env` | `OPENAI_API_KEY`, model settings, upload limits. |
| `/home/glitchy/blog/.env` | `WATCHTOWER_TOKEN` for webhook updates. |
| `/home/glitchy/observing/.env` | `GRAFANA_ADMIN_PASSWORD` and pinned image versions. |
| `/home/glitchy/openclaw/.env` | OpenClaw gateway, auth, telemetry, and provider settings. |
| `/home/glitchy/monke-proxy/.env` | `API_URL`, `APE_KEY`, and local bind settings. |
| `/home/glitchy/.docker/config.json` | GHCR pull credentials used by the blog/watchtower stack. |
| Cloudflare tunnel token or `/etc/cloudflared` credentials | Reconnects public tunnels after rebuild. |
| GitHub deploy key or user SSH key | Lets Ansible clone private repositories. |

## Required if OpenClaw state must survive

| Path | Notes |
| --- | --- |
| `/home/glitchy/.openclaw` | OpenClaw state, workspace, identity, plugins, memory, media, logs, tasks, and credentials. Contains secrets. |
| `/home/glitchy/.openclaw-auth-profile-secrets` | Auth profile secrets. Contains secrets. |

## Required if k3s state must survive

| Path | Notes |
| --- | --- |
| `/etc/rancher/k3s/k3s.yaml` | Cluster-admin kubeconfig. Secret. |
| `/var/lib/rancher/k3s` | k3s cluster datastore and runtime state. Prefer a full encrypted disk backup if you need exact cluster state. |

For this host, k3s currently appears to run only default components. If no custom workloads are stored in k3s, reinstalling k3s from this repo is enough.

## Optional runtime history

Observability history lives in Docker volumes:

- `monke-proxy_redis_data`
- `observing_grafana-data`
- `observing_prometheus-data`
- `observing_loki-data`
- `observing_tempo-data`
- `observing_alloy-data`

The provisioned dashboards and datasources are already stored in `Glitchyi/observing`; the volumes are only needed for history and Grafana runtime state.
