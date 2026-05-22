#!/usr/bin/env bash
# =============================================================================
# install-k3s-worker.sh
# Joins a K3s Worker Node to an existing Control Plane
# Author: Bartosz Suszko | SRE Homelab Project
#
# Usage: ./install-k3s-worker.sh <WORKER_HOSTNAME> <WORKER_IP> <NODE_TOKEN>
# Example: ./install-k3s-worker.sh k3s-worker1 192.168.122.11 K10a3b...
# =============================================================================
set -euo pipefail

# ─── Arguments ────────────────────────────────────────────────────────────────
WORKER_HOSTNAME="${1:-}"
WORKER_IP="${2:-}"
NODE_TOKEN="${3:-}"
MASTER_IP="192.168.122.10"
K3S_VERSION="v1.35.4+k3s1"

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ─── Validate arguments ───────────────────────────────────────────────────────
validate_args() {
  if [[ -z "$WORKER_HOSTNAME" || -z "$WORKER_IP" || -z "$NODE_TOKEN" ]]; then
    die "Usage: $0 <WORKER_HOSTNAME> <WORKER_IP> <NODE_TOKEN>
    Example: $0 k3s-worker1 192.168.122.11 K10abc..."
  fi

  if [[ ! "$WORKER_HOSTNAME" =~ ^k3s-worker[0-9]+$ ]]; then
    die "Hostname '$WORKER_HOSTNAME' does not match pattern k3s-workerN. Fix before proceeding to avoid etcd split-brain."
  fi

  log "Arguments validated: hostname=$WORKER_HOSTNAME ip=$WORKER_IP"
}

# ─── Preflight checks ─────────────────────────────────────────────────────────
preflight() {
  log "Running preflight checks..."

  CURRENT_HOSTNAME=$(hostname)
  if [[ "$CURRENT_HOSTNAME" != "$WORKER_HOSTNAME" ]]; then
    log "Setting hostname to $WORKER_HOSTNAME (was: $CURRENT_HOSTNAME)"
    sudo hostnamectl set-hostname "$WORKER_HOSTNAME"
    # Update /etc/hosts
    sudo sed -i "s/$CURRENT_HOSTNAME/$WORKER_HOSTNAME/g" /etc/hosts
    log "Hostname updated. A re-login may be needed for prompt to refresh."
  fi

  # Test connectivity to master
  if ! ping -c 2 -W 3 "$MASTER_IP" &>/dev/null; then
    die "Cannot reach master at $MASTER_IP. Check network configuration."
  fi

  # Test K3s API connectivity
  if ! curl -sk --max-time 5 "https://${MASTER_IP}:6443/healthz" | grep -q "ok"; then
    die "K3s API at $MASTER_IP:6443 is not reachable or not healthy."
  fi

  log "Preflight checks passed. Master is reachable."
}

# ─── System preparation ───────────────────────────────────────────────────────
prepare_system() {
  log "Preparing system..."

  sudo swapoff -a
  sudo sed -i '/swap/d' /etc/fstab

  sudo modprobe overlay
  sudo modprobe br_netfilter

  cat <<EOF | sudo tee /etc/modules-load.d/k3s.conf
overlay
br_netfilter
EOF

  cat <<EOF | sudo tee /etc/sysctl.d/99-k3s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                  = 1
EOF
  sudo sysctl --system

  log "System preparation complete."
}

# ─── Join cluster ─────────────────────────────────────────────────────────────
join_cluster() {
  log "Joining cluster as worker node: $WORKER_HOSTNAME..."

  curl -sfL https://get.k3s.io | \
    INSTALL_K3S_VERSION="${K3S_VERSION}" \
    K3S_URL="https://${MASTER_IP}:6443" \
    K3S_TOKEN="${NODE_TOKEN}" \
    sh -s - \
    --node-ip "${WORKER_IP}" \
    --node-name "${WORKER_HOSTNAME}"

  log "Worker agent installed. Waiting for node to register..."
  sleep 15
}

# ─── Verify from master (SSH) ─────────────────────────────────────────────────
verify() {
  log "Worker node $WORKER_HOSTNAME joined the cluster."
  log "Verify from master with:"
  echo ""
  echo "  ssh user@${MASTER_IP} 'sudo k3s kubectl get nodes'"
  echo ""
  log "Node $WORKER_HOSTNAME should show STATUS=Ready within 30 seconds."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  log "Starting K3s Worker installation on $(hostname) ($(date))"
  validate_args
  preflight
  prepare_system
  join_cluster
  verify
}

main "$@"
