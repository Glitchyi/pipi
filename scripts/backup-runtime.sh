#!/usr/bin/env bash
set -euo pipefail

server_home="${SERVER_HOME:-/home/glitchy}"
timestamp="$(date -u +%Y%m%d-%H%M%SZ)"
backup_root="${BACKUP_ROOT:-${server_home}/backups/homelab-${timestamp}}"
volume_image="${BACKUP_VOLUME_IMAGE:-alpine:3.20}"
include_secrets="${INCLUDE_SECRETS:-0}"

volumes=(
  monke-proxy_redis_data
  observing_alloy-data
  observing_grafana-data
  observing_loki-data
  observing_prometheus-data
  observing_tempo-data
)

secret_paths=(
  "${server_home}/ATS/.env"
  "${server_home}/blog/.env"
  "${server_home}/observing/.env"
  "${server_home}/openclaw/.env"
  "${server_home}/monke-proxy/.env"
  "${server_home}/.docker/config.json"
  "${server_home}/.openclaw"
  "${server_home}/.openclaw-auth-profile-secrets"
  "/etc/cloudflared"
  "/etc/rancher/k3s/k3s.yaml"
)

mkdir -p "${backup_root}/manifests" "${backup_root}/volumes" "${backup_root}/secrets"

{
  echo "backup_created_utc=${timestamp}"
  echo "server_home=${server_home}"
  echo "include_secrets=${include_secrets}"
  echo
  echo "[compose_projects]"
  docker compose ls --all || true
  echo
  echo "[docker_volumes]"
  docker volume ls || true
  echo
  echo "[secret_paths]"
  for path in "${secret_paths[@]}"; do
    if [ -e "${path}" ]; then
      echo "present ${path}"
    else
      echo "missing ${path}"
    fi
  done
} > "${backup_root}/manifests/backup-summary.txt"

for volume in "${volumes[@]}"; do
  if docker volume inspect "${volume}" >/dev/null 2>&1; then
    docker run --rm \
      -v "${volume}:/volume:ro" \
      -v "${backup_root}/volumes:/backup" \
      "${volume_image}" \
      sh -c "cd /volume && tar czf /backup/${volume}.tar.gz ."
  else
    echo "Skipping missing Docker volume: ${volume}" >&2
  fi
done

if [ "${include_secrets}" = "1" ]; then
  existing_secret_paths=()
  for path in "${secret_paths[@]}"; do
    if [ -e "${path}" ]; then
      existing_secret_paths+=("${path}")
    fi
  done

  if [ "${#existing_secret_paths[@]}" -gt 0 ]; then
    tar czf "${backup_root}/secrets/secrets-and-state.tar.gz" "${existing_secret_paths[@]}"
  fi
else
  cat > "${backup_root}/secrets/README.txt" <<'EOF'
Secret contents were not included.

Rerun with INCLUDE_SECRETS=1 only when BACKUP_ROOT points to an encrypted or otherwise protected destination.
EOF
fi

echo "Backup written to ${backup_root}"
