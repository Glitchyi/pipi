# pipi project documentation

Snapshot date: 2026-05-29 IST.

This document is the deep project map for the `pipi` host. It documents the
projects deployed under `/home/glitchy`, how they connect to GitHub, what they
run, what state they need, and how they are monitored.

The authoritative restore inventory is still `group_vars/servers.yaml`. This
file explains the projects in operational terms and links the GitHub
repositories that back them. Secrets are intentionally described only by file
name or environment variable name; secret values do not belong in git.

## Project index

The active host projects are:

- `pipi`: recovery, host setup, and project inventory.
- `ATS`: resume scanner web application.
- `blog`: Astro blog and Watchtower update endpoint.
- `monke-proxy`: local Monkeytype proxy/cache for external consumers.
- `observing`: Grafana, Prometheus, Loki, Tempo, Alloy, and exporters.
- `openclaw`: local OpenClaw gateway and stateful assistant runtime.

GitHub repositories:

- `pipi`: <https://github.com/Glitchyi/pipi>
- `ATS`: <https://github.com/Glitchyi/ATS>
- `blog`: <https://github.com/Glitchyi/blog>
- `monke-proxy`: <https://github.com/Glitchyi/monke-proxy>
- `observing`: <https://github.com/Glitchyi/observing>
- `openclaw`: <https://github.com/openclaw/openclaw>

## System shape

`pipi` is a Raspberry Pi homelab node. Application projects are primarily
Docker Compose projects in `/home/glitchy`. K3s is installed and running as a
single-node cluster, but the listed applications currently run as Compose
projects unless they are explicitly migrated later.

The high-level responsibility split is:

- `pipi` restores the machine and clones the projects.
- Docker Compose runs the current app stack.
- K3s provides an on-device Kubernetes platform for future or separate
  workloads.
- `observing` is the telemetry plane for host, container, app, and K3s signals.
- Cloudflare Tunnel ingress is managed outside this repo by design.

Current service exposure:

- Public host ports: `3000`, `3002`, `3003`, `3030`, `18789`, `18790`.
- Local-only app ports: `8080` for `monke-proxy`.
- Local-only telemetry ports: `9090`, `3100`, `3200`, `12345`, `4317`, `4318`.
- K3s-related listeners: `6443/tcp`, `6444/tcp`, `10250/tcp`, `8472/udp`, and
  localhost-only Kubernetes internals.

## pipi

Repository: <https://github.com/Glitchyi/pipi>
Local path: `/home/glitchy/pipi`
Primary files: `main.yaml`, `group_vars/servers.yaml`, `compose-projects.yaml`,
`k3s.yaml`, `cloudflared.yaml`, `scripts/validate-recovery.sh`, `docs/`

### Role

`pipi` is the recovery and host-configuration repository. It should be the first
repository cloned on a new host because it describes the rest of the machine.
Its job is to install base packages, Docker, K3s, Cloudflared, terminal tooling,
and the known project repositories.

The repo does not contain live secrets. It records what secret files and keys
must exist so a restored machine can be validated without committing private
material.

### Runtime and restore model

The main restore command is:

```sh
ansible-playbook -i inventory.yaml main.yaml
```

That playbook prepares the host and clones project repositories. It validates
Compose files only when the required project env files exist.

Compose projects are not started by default because the secrets and state files
must be restored first. After restoring secrets, start projects with:

```sh
ansible-playbook -i inventory.yaml main.yaml -e restore_start_compose=true
```

### Important state

The repo expects these state categories to be restored from encrypted backup or
a password manager:

- Per-project `.env` files.
- Cloudflare tunnel credentials and token material.
- Docker registry credentials, especially for private GHCR pulls.
- OpenClaw state, auth profiles, and session material.
- K3s kubeconfig if it is needed from the `glitchy` user account.
- Observability Docker volumes if historical metrics, logs, traces, or Grafana
  state should survive a rebuild.

### Operational checks

Use:

```sh
./scripts/validate-recovery.sh
```

Then validate the live runtime:

```sh
docker compose ls --all
docker ps
kubectl get nodes
kubectl get pods -A
```

If `kubectl` cannot read the K3s kubeconfig as `glitchy`, restore or recreate
the user kubeconfig rather than loosening the system kubeconfig globally.

## ATS

Repository: <https://github.com/Glitchyi/ATS>
Local path: `/home/glitchy/ATS`
Compose project: `ats`
Primary service: `ats-scan`

### Role

`ATS` is a resume scanner web application. It accepts PDF, DOCX, and text
resume uploads, runs deterministic ATS and readability checks, and can call
OpenAI for structured recommendations when the OpenAI key is present.

### Runtime

The service is built locally from the repository by Docker Compose. The app is a
Next.js application and listens inside the container on port `3000`.

Published port:

```text
0.0.0.0:3000 -> ats-scan:3000
```

Health endpoint:

```text
http://127.0.0.1:3000/api/health
```

### Required configuration

Required secret file:

```text
/home/glitchy/ATS/.env
```

Required key:

```text
OPENAI_API_KEY
```

Other relevant configuration may include:

```text
OPENAI_MODEL
MAX_RESUME_BYTES
```

### Data flow

Typical request flow:

```text
Browser or API client
  -> ATS Next.js route
  -> resume parser for PDF, DOCX, or text
  -> deterministic ATS/readability scoring
  -> optional OpenAI structured recommendation call
  -> response rendered in the web app
```

### Observability

`observing` monitors `ATS` through:

- Docker container logs sent through Alloy to Loki.
- Container CPU, memory, filesystem, and network metrics from cAdvisor.
- Host metrics from node-exporter.
- Blackbox HTTP probing of the published app port.
- A dedicated Grafana project dashboard.

### Recovery and failure modes

Recovery order:

1. Clone or update the repository through the `pipi` playbook.
2. Restore `/home/glitchy/ATS/.env`.
3. Start with Docker Compose using a local build.
4. Check `/api/health`.
5. Check the `ATS` Grafana dashboard and Loki logs.

Common issues:

- Missing `OPENAI_API_KEY` prevents AI recommendations.
- Upload limits or parser errors affect specific resume files.
- A failed local build usually points to dependency or Node image issues.
- Port `3000` must remain reserved for this service.

## blog

Repository: <https://github.com/Glitchyi/blog>
Local path: `/home/glitchy/blog`
Compose project: `blog`
Primary services: `astro-app`, `watchtower`

### Role

`blog` is the Astro-based site. Content lives in the repository, including
architecture posts under the repository content structure. Runtime deployment on
`pipi` uses a container image rather than a local build.

### Runtime

The app service runs from:

```text
ghcr.io/glitchyi/blog:latest
```

Published ports:

```text
0.0.0.0:3002 -> astro-app:80
0.0.0.0:3003 -> watchtower:8080
```

`watchtower` exposes an HTTP API endpoint for update triggers and uses Docker
socket access to update the running container.

### Required configuration

Required secret files:

```text
/home/glitchy/blog/.env
/home/glitchy/.docker/config.json
```

Required key:

```text
WATCHTOWER_TOKEN
```

The Docker config is required when the host must authenticate to GHCR.

### Deployment flow

Typical deployment flow:

```text
GitHub repository update
  -> image build and publish to GHCR
  -> Watchtower webhook or polling trigger
  -> Pi pulls ghcr.io/glitchyi/blog:latest
  -> astro-app container is replaced
```

### Observability

`observing` monitors `blog` through:

- Docker logs from `astro-app` and `watchtower`.
- cAdvisor container resource metrics.
- Blackbox HTTP probing of the app port.
- A dedicated Grafana project dashboard.

### Recovery and failure modes

Recovery order:

1. Restore `/home/glitchy/blog/.env`.
2. Restore `/home/glitchy/.docker/config.json`.
3. Start the Compose project.
4. Check `http://127.0.0.1:3002`.
5. Check Watchtower logs if updates are not applying.

Common issues:

- GHCR authentication prevents image pulls.
- `WATCHTOWER_TOKEN` mismatch prevents webhook-driven updates.
- Published port `3003` should be protected if exposed beyond trusted paths.
- A stale image tag means the host is healthy but the app is not current.

## monke-proxy

Repository: <https://github.com/Glitchyi/monke-proxy>
Local path: `/home/glitchy/monke-proxy`
Compose project: `monke-proxy`
