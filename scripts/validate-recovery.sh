#!/usr/bin/env bash
set -u

failures=0

section() {
  printf '\n== %s ==\n' "$1"
}

ok() {
  printf 'ok: %s\n' "$1"
}

warn() {
  printf 'warn: %s\n' "$1"
}

fail() {
  printf 'fail: %s\n' "$1"
  failures=$((failures + 1))
}

require_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 is installed"
  else
    fail "$1 is missing"
  fi
}

section "Host commands"
for cmd in git docker k3s kubectl cloudflared; do
  require_cmd "$cmd"
done

section "K3s"
if systemctl is-active --quiet k3s; then
  ok "k3s service is active"
else
  fail "k3s service is not active"
fi

if k3s --version >/tmp/pipi-k3s-version.txt 2>/dev/null; then
  ok "$(head -n 1 /tmp/pipi-k3s-version.txt)"
else
  warn "could not read k3s version"
fi

if kubectl get nodes >/tmp/pipi-kubectl-nodes.txt 2>/tmp/pipi-kubectl-error.txt; then
  ok "kubectl can query nodes"
  cat /tmp/pipi-kubectl-nodes.txt
else
  warn "kubectl cannot query nodes: $(tr '\n' ' ' </tmp/pipi-kubectl-error.txt)"
fi

section "Docker"
if docker info >/dev/null 2>&1; then
  ok "docker daemon is reachable"
else
  fail "docker daemon is not reachable"
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose plugin is available"
else
  fail "docker compose plugin is missing"
fi

docker compose ls --all 2>/dev/null || warn "could not list compose projects"

section "Compose project files"
for project in ATS blog observing openclaw monke-proxy; do
  dir="/home/glitchy/$project"
  if [ -d "$dir/.git" ]; then
    ok "$project repo exists"
  else
    fail "$project repo is missing at $dir"
    continue
  fi

  if [ -f "$dir/docker-compose.yml" ]; then
    ok "$project compose file exists"
  else
    fail "$project docker-compose.yml is missing"
  fi

  if [ -f "$dir/.env" ]; then
    ok "$project .env exists"
    if (cd "$dir" && docker compose config --quiet >/dev/null 2>&1); then
      ok "$project compose config validates"
    else
      fail "$project compose config failed"
    fi
  else
    warn "$project .env missing; restore secrets before starting"
  fi
done

section "Expected ports"
if command -v ss >/dev/null 2>&1; then
  ss -ltnup 2>/dev/null | awk 'NR == 1 || /:3000|:3002|:3003|:3030|:8080|:18789|:18790|:6443|:8472|:9090|:3100|:3200|:4317|:4318|:12345/'
else
  warn "ss is missing"
fi

section "Result"
if [ "$failures" -eq 0 ]; then
  ok "recovery validation completed without hard failures"
else
  fail "$failures hard failure(s) detected"
fi

exit "$failures"
