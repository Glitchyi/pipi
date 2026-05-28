# Disaster recovery runbook

Use this when rebuilding `pipi` after a disk, OS, or hardware failure.

## 1. Prepare the host

1. Install Raspberry Pi OS or Debian on the replacement machine.
2. Create user `glitchy`.
3. Enable SSH.
4. Add a GitHub SSH key for `glitchy`, or restore the encrypted backup of the existing key.
5. Install Ansible on the control machine.

## 2. Clone this repo

```sh
git clone git@github.com:Glitchyi/pipi.git
cd pipi
```

Update `inventory.yaml` if the host IP changed.

## 3. Run the base playbook

```sh
ansible-playbook -i inventory.yaml main.yaml
```

This installs packages, Docker, k3s, cloudflared, terminal tooling, and clones the known project repos.

## 4. Restore secrets and state

Restore the files listed in `docs/secrets.md`. At minimum, restore the `.env` files for:

- `/home/glitchy/ATS`
- `/home/glitchy/blog`
- `/home/glitchy/observing`
- `/home/glitchy/openclaw`
- `/home/glitchy/monke-proxy`

Restore Cloudflare tunnel credentials and OpenClaw state if those services need to preserve identity or sessions.

For routine backups before a rebuild or disk replacement, write runtime backups to a protected external path:

```sh
BACKUP_ROOT=/mnt/backup/homelab-$(date -u +%Y%m%d-%H%M%SZ) ./scripts/backup-runtime.sh
```

Set `INCLUDE_SECRETS=1` only when `BACKUP_ROOT` points to encrypted storage. The default backup exports Docker volumes and writes a manifest, but does not copy secret contents.

## 5. Start Compose projects

After secrets are restored:

```sh
ansible-playbook -i inventory.yaml main.yaml -e restore_start_compose=true
```

Expected local Cloudflare Tunnel target for `monke-proxy`:

```text
http://127.0.0.1:8080
```

Expected externally reachable service ports if you choose to publish them directly:

- `3000`: ATS
- `3002`: blog
- `3003`: watchtower webhook endpoint
- `3030`: Grafana
- `18789`: OpenClaw gateway
- `18790`: OpenClaw bridge

## 6. Validate

```sh
./scripts/validate-recovery.sh
```

Manual checks:

```sh
docker compose ls --all
docker ps
kubectl get nodes
kubectl get pods -A
```

If `kubectl` cannot read the kubeconfig, check that `/home/glitchy/.kube/config` exists or rerun the k3s tasks.
