# Pi fleet status

Updated: 28 October 2026. This summarizes the deployed systems and recorded verification; it is not a live health dashboard.

## Systems

| Host | Hardware and storage | Role |
|---|---|---|
| pipi | Raspberry Pi 5, 16 GB RAM; USB OS; existing NVMe data drive preserved | Jellyfin, Home Assistant, Node Exporter and cAdvisor |
| popo | Raspberry Pi 5, 8 GB RAM; microSD OS | Hermes/Kuttu, Grafana, Prometheus, Node Exporter and cAdvisor |

Tailscale and cloudflared are native services on both hosts. Applications use Docker Compose managed by systemd. Neither Pi is configured as a Tailscale exit node. Private addresses, credentials and keys are intentionally omitted from this public status document.

## Completed

- [x] Base OS configuration, package upgrades and one-at-a-time reboot checks.
- [x] Persistent Ethernet configuration with existing Wi-Fi fallback retained.
- [x] Key-only SSH, verified from Windows and Mac; existing client keys retained.
- [x] Existing NVMe mounted without formatting or erasing data.
- [x] Jellyfin and supported Home Assistant Container deployed on pipi.
- [x] Grafana and Prometheus deployed on popo, with a provisioned dashboard and five verified monitoring targets.
- [x] Node Exporter and cAdvisor deployed on both hosts; memory accounting and container limits verified.
- [x] Separate native Cloudflare tunnels enrolled, enabled at boot and checked after restart. Application routes remain a later configuration step.
- [x] Separate GitHub SSH identities configured and verified for both hosts.
- [x] Persistent journals and rotating container logs configured.
- [x] Temporary setup artifacts cleaned up while retaining maintenance and recovery scripts.

## Hermes / Kuttu

- [x] Hermes runs on popo with persistent private state and Codex device authentication.
- [x] Existing Telegram bot connected, restricted to the owner's account; an end-to-end reply was confirmed.
- [x] Kuttu's persona focuses on practical computer science, software engineering, Linux, networking and debugging.
- [x] Bundled skills reduced to five essentials: codebase inspection, systematic debugging, GitHub, grounded citations and Hermes maintenance. Automatic bundled-skill seeding is disabled.
- [x] Password-protected LAN web dashboard enabled on TCP 9119. No public tunnel route was added; gateway API TCP 8642 remains internal to the container.
- [x] Dedicated management SSH identity allows Kuttu on popo to access both hosts with strict host-key checking and no saved sudo password.
- [x] Persistent fleet context describes both systems, service layout, access, maintenance scope and preservation rules.

## Maintenance and service ledger

| Task | Schedule (IST) | Behavior |
|---|---|---|
| pipi native connector updates | Daily 04:00 | Update Tailscale/cloudflared packages; restart connectors when versions change; catch up on missed runs |
| popo native connector updates | Daily 04:30 | Same policy, staggered from pipi |
| Kuttu fleet care | Daily 09:00 | Deterministic checks, inventory refresh and narrowly scoped cleanup; no model inference |

Daily care checks reachability, expected containers, native services, failed systemd units, disk space, memory, the NVMe mount, listening ports and reboot requests. Both connector update services passed a manual test run.

Each host keeps a port inventory in its user's home `agents.md`. Popo keeps the current service ledger as `ledger.md` and `ledger.json`, plus bounded `service-changes.jsonl` and `maintenance.jsonl` history under the private Hermes fleet directory. These runtime records remain on the hosts rather than in this repository.

Automatic cleanup is limited to regular files older than seven days directly inside Kuttu's own maintenance cache. Application data, media, downloads, backups and unrelated files are preserved. Application upgrades, broad deletion, reboots and consequential configuration changes require owner approval. Automatic maintenance reports stay local; ordinary Telegram chat remains enabled.

## Pending

- [ ] Confirm Jellyfin's first user and media-library setup.
- [ ] Confirm Home Assistant owner onboarding and required integrations. Container mode has no Supervisor/add-on manager.
- [ ] Confirm the owner's first Grafana login; backend authentication and dashboard checks have already passed.
- [ ] Configure Cloudflare application hostnames/private routes if needed.
- [ ] Verify Tailscale SSH and application access from outside the home LAN.
- [ ] Replace the temporary local/sudo account password; SSH already requires keys.
- [ ] Review popo's failed `smartmontools.service`: it reports no SMART-capable devices on the microSD-only installation. No service change has been made.
- [ ] Publish and review the separate deployment automation changes. This status update does not publish those working-tree changes.
- [ ] Optionally authorize automatic external maintenance notifications; these are currently disabled.

## Setup history

Work progressed through USB/OS preparation, base provisioning, SSH and networking, application/monitoring deployment, Cloudflare onboarding and connector updates, then Hermes authentication, Telegram, the Kuttu persona, LAN dashboard and fleet care.

The four related setup chats are grouped locally under **Pi Fleet — pipi & popo**. Private chat transcripts and credentials are not included here.
