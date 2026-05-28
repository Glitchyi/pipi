# pipi

Ansible and recovery notes for rebuilding the `pipi` Raspberry Pi homelab host.

This repository is intended to recreate the machine configuration and project layout after a disk or host failure. It does not store live secrets. Restore `.env` files, Cloudflare tunnel credentials, GitHub/registry credentials, OpenClaw state, and k3s kubeconfig from an encrypted backup or password manager.

## Quick Restore

```sh
ansible-playbook -i inventory.yaml main.yaml
```

By default, the playbook installs host tooling, k3s, cloudflared, and clones the known project repos. It does not start Docker Compose projects unless `restore_start_compose=true` is provided after secrets have been restored.

```sh
ansible-playbook -i inventory.yaml main.yaml -e restore_start_compose=true
```

## Validate A Restored Host

```sh
./scripts/validate-recovery.sh
```

See:

- `docs/projects.md` for the deep project map, GitHub links, dependencies, and runbooks.
- `docs/system-inventory.md` for the current service map.
- `docs/secrets.md` for the secret and state items that must be backed up outside git.
- `docs/disaster-recovery.md` for the restore order.
