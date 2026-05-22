#!/usr/bin/env bash
# =============================================================================
# install-k3s-master.sh
# Bootstraps a K3s Control Plane node on Ubuntu Server 24.04 LTS
# Author: Bartosz Suszko | SRE Homelab Project
# =============================================================================
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
MASTER_IP="192.168.122.10"
K3S_VERSION="v1.35.4+k3s1"
KUBECONFIG_DIR="$HOME/.kube"

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ─── Preflight checks ─────────────────────────────────────────────────────────
preflight() {
  log "Running preflight checks..."

  # Validate hostname matches expected pattern (prevent etcd split-brain)
  HOSTNAME=$(hostname)
  if [[ "$HOSTNAME" != "k3s-master" ]]; then
    die "Hostname is '$HOSTNAME', expected 'k3s-master'. Fix with: sudo hostnamectl set-hostname k3s-master"
  fi

  # Validate static IP is configured
  CURRENT_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127 | head -1)
  if [[ "$CURRENT_IP" != "$MASTER_IP" ]]; then
    warn "Current IP: $CURRENT_IP — expected $MASTER_IP. Ensure static IP is configured."
  fi

  # Check OS
  if ! grep -q "Ubuntu 24.04" /etc/os-release 2>/dev/null; then
    warn "Expected Ubuntu 24.04 LTS. Detected: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2)"
  fi

  log "Preflight checks passed."
}

# ─── System preparation ───────────────────────────────────────────────────────
prepare_system() {
  log "Preparing system..."

  # Disable swap (required by Kubernetes)
  sudo swapoff -a
  sudo sed -i '/swap/d' /etc/fstab

  # Load required kernel modules
  sudo modprobe overlay
  sudo modprobe br_netfilter

  # Persist kernel modules
  cat <<EOF | sudo tee /etc/modules-load.d/k3s.conf
overlay
br_netfilter
EOF

  # Set required sysctl params
  cat <<EOF | sudo tee /etc/sysctl.d/99-k3s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                  = 1
EOF
  sudo sysctl --system

  log "System preparation complete."
}

# ─── Install K3s Control Plane ────────────────────────────────────────────────
install_k3s() {
  log "Installing K3s Control Plane (version: ${K3S_VERSION})..."

  curl -sfL https://get.k3s.io | \
    INSTALL_K3S_VERSION="${K3S_VERSION}" \
    sh -s - \
    --write-kubeconfig-mode 644 \
    --node-ip "${MASTER_IP}" \
    --advertise-address "${MASTER_IP}" \
    --tls-san "${MASTER_IP}"

  # Wait for k3s to be ready
  log "Waiting for K3s to become ready..."
  sleep 10
  sudo k3s kubectl wait --for=condition=Ready node --all --timeout=120s

  log "K3s Control Plane installed successfully."
}

# ─── Configure kubeconfig ─────────────────────────────────────────────────────
configure_kubeconfig() {
  log "Configuring kubeconfig for user: $USER"

  mkdir -p "${KUBECONFIG_DIR}"
  sudo cp /etc/rancher/k3s/k3s.yaml "${KUBECONFIG_DIR}/config"
  sudo chown "${USER}:${USER}" "${KUBECONFIG_DIR}/config"
  chmod 600 "${KUBECONFIG_DIR}/config"

  # Replace localhost with actual IP in kubeconfig
  sed -i "s/127.0.0.1/${MASTER_IP}/g" "${KUBECONFIG_DIR}/config"

  export KUBECONFIG="${KUBECONFIG_DIR}/config"
  echo "export KUBECONFIG=${KUBECONFIG_DIR}/config" >> ~/.bashrc

  log "kubeconfig configured at ${KUBECONFIG_DIR}/config"
}

# ─── Output node token ────────────────────────────────────────────────────────
output_token() {
  log "Retrieving Node Token for worker registration..."
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  NODE TOKEN (copy this for worker installation):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  sudo cat /var/lib/rancher/k3s/server/node-token
  echo ""
  echo "  K3S_URL: https://${MASTER_IP}:6443"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ─── Verify installation ──────────────────────────────────────────────────────
verify() {
  log "Verifying installation..."
  kubectl get nodes -o wide
  kubectl get pods -A
  log "Installation complete. Control Plane is READY."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  log "Starting K3s Master installation on $(hostname) ($(date))"
  preflight
  prepare_system
  install_k3s
  configure_kubeconfig
  output_token
  verify
}

main "$@"
