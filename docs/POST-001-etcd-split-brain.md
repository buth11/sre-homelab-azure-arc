# POST-001: K3s Worker Node Split-Brain — etcd Re-authorization Failure

| Field            | Value                                          |
|------------------|------------------------------------------------|
| Incident ID      | POST-001                                       |
| Date             | May 2026                                       |
| Severity         | P2 — Degraded cluster capacity                 |
| Duration         | < 7 minutes (detection to resolution)          |
| Affected         | k3s-worker1, cluster operating at 2/3 capacity |
| Detected by      | Manual observation during cluster setup        |
| Resolved by      | Bartosz Suszko (SRE)                           |
| Status           | Resolved — Action items implemented            |

---

## Impact

During the cluster bootstrapping phase, one of three worker nodes (`k3s-worker1`) failed
to join the cluster due to a hostname mismatch. The cluster operated at **66% capacity**
(1 master + 1 worker instead of 1 master + 2 workers) for approximately 7 minutes.

No running workloads were interrupted — the Kubernetes scheduler automatically placed
all pods on the available nodes via ReplicaSet logic, maintaining full application
availability throughout the incident.

**Error observed in terminal:**

```
FATA[0034] Node password rejected, duplicate hostname or contents of
'/etc/rancher/node/password' may not match server
```

---

## Timeline

| Time  | Event                                                                 |
|-------|-----------------------------------------------------------------------|
| T+0   | Worker node provisioned with a typo in hostname: `ks3-worker1`        |
| T+1m  | K3s join command executed — agent connected with incorrect hostname   |
| T+2m  | Attempt to rename via `hostnamectl set-hostname k3s-worker1`          |
| T+3m  | etcd rejected re-authorization — Split-Brain state detected           |
| T+4m  | **Decision:** delete stale entry from Kubernetes API instead of patching in-place |
| T+5m  | `kubectl delete node ks3-worker1` executed — etcd record cleared      |
| T+6m  | `/etc/hosts` updated on worker VM, `k3s-agent` service restarted     |
| T+7m  | Node re-registered with correct hostname, STATUS=Ready confirmed      |

---

## Root Cause

A typographical error during VM provisioning produced the hostname `ks3-worker1`
instead of the intended `k3s-worker1` (characters `s` and `3` were transposed).

When the K3s agent registered with etcd under the incorrect name and a hostname
change was subsequently attempted via `hostnamectl`, etcd detected the node password
mismatch between the registered identity and the new connection attempt. This is a
known etcd protection mechanism against unauthorized node substitution
(Split-Brain prevention).

**Root cause chain:**

```
Human error (typo in hostname)
    → K3s agent registers under wrong identity in etcd
        → Rename attempt creates identity conflict
            → etcd rejects re-authorization (Split-Brain protection)
                → Node stuck in NotReady / unregistered state
```

---

## Resolution

The correct remediation was to treat this as a **node replacement** rather than a
**node rename**:

```bash
# Step 1: Remove the stale node record from the control plane
sudo k3s kubectl delete node ks3-worker1

# Step 2: On the worker VM — correct hostname and hosts file
sudo hostnamectl set-hostname k3s-worker1
sudo sed -i 's/ks3-worker1/k3s-worker1/g' /etc/hosts

# Step 3: Clear stale K3s agent identity
sudo rm -rf /etc/rancher/node/

# Step 4: Restart agent to re-register with clean identity
sudo systemctl restart k3s-agent

# Step 5: Verify from master
sudo k3s kubectl get nodes
```

**Key insight:** etcd is an append-only distributed key-value store that uses node
identity for quorum decisions. Renaming a registered node in-place creates a duplicate
identity conflict. The only safe remediation is to delete the stale record and allow
the agent to re-register from scratch.

---

## What Went Well

- No running workloads were disrupted — ReplicaSet HA design absorbed the failure
- Root cause was identified quickly by reading the exact error message from the K3s agent log
- The remediation procedure was executed cleanly in under 3 minutes once diagnosed
- No data loss in etcd

---

## What Could Be Improved

- No hostname validation existed before the node join command was executed
- The provisioning process was fully manual — no automated checks

---

## Action Items

| # | Action                                                               | Owner          | Due     | Status      |
|---|----------------------------------------------------------------------|----------------|---------|-------------|
| 1 | Add hostname regex validation to `install-k3s-worker.sh` before join | Bartosz Suszko | Week 1  | Done        |
| 2 | Add connectivity pre-check to master API before agent install        | Bartosz Suszko | Week 1  | Done        |
| 3 | Document node replacement procedure in runbook                       | Bartosz Suszko | Week 1  | Done (this) |
| 4 | Consider Ansible playbook for idempotent node provisioning           | Bartosz Suszko | Week 2  | Backlog     |

---

## Lessons Learned

> "The K3s etcd Split-Brain protection is a feature, not a bug. The correct mental
> model is: once a node is registered with an identity, that identity is immutable.
> Treat hostname correction as a node replacement, not a node rename."

This incident reinforced a core SRE principle: **read the error message carefully
before taking action**. The urge to "fix" the hostname with `hostnamectl` was
intuitive but incorrect — the right action was to first remove the stale
registration from the control plane, then re-provision the node identity.

---

*This postmortem was written following the blameless postmortem methodology.
The goal is to learn from the incident, not to assign blame.*
