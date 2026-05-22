# KQL Queries — SRE Homelab Azure Arc
# Log Analytics Workspace: DefaultWorkspace-WEU
# Author: Bartosz Suszko
# Run these in: Azure Portal → Log Analytics Workspace → Logs

---

## 1. Node Inventory — current state of all cluster nodes

```kusto
KubeNodeInventory
| where TimeGenerated > ago(1h)
| summarize arg_max(TimeGenerated, *) by Computer
| project
    Computer,
    Status,
    KubeletVersion,
    CPUCores       = CPUCapacityNanoCores / 1000000000,
    RAMgb          = round(toreal(MemoryCapacityBytes) / 1073741824, 1)
| order by Computer asc
```

**Expected result:** 3 rows — k3s-master, k3s-worker1, k3s-worker2, all Status=Ready

---

## 2. Pod Status per Namespace — operational overview

```kusto
KubePodInventory
| where TimeGenerated > ago(1h)
| summarize arg_max(TimeGenerated, *) by Name, Namespace
| summarize PodCount = count() by Namespace, PodStatus
| order by Namespace asc, PodCount desc
```

**Use case:** Quick triage during incident — which namespace has pods not Running?

---

## 3. Warning Events — SRE alerting baseline

```kusto
KubeEvents
| where TimeGenerated > ago(6h)
| where Type == "Warning"
| project TimeGenerated, Namespace, Name, Reason, Message
| order by TimeGenerated desc
| take 50
```

**Use case:** First query to run when an alert fires. Shows what Kubernetes observed.

---

## 4. OOMKill Detection — memory pressure alert

```kusto
KubeEvents
| where TimeGenerated > ago(24h)
| where Type == "Warning"
| where Reason == "OOMKilling"
| project TimeGenerated, Namespace, Name, Message
| order by TimeGenerated desc
```

**Use case:** Detect containers exceeding memory limits before they cascade.
**SRE action:** Increase memory limit or investigate memory leak.

---

## 5. Pod Restart Count — reliability metric

```kusto
KubePodInventory
| where TimeGenerated > ago(24h)
| summarize arg_max(TimeGenerated, *) by Name, Namespace
| where PodRestartCount > 0
| project Namespace, Name, PodRestartCount, PodStatus, ContainerLastStatus
| order by PodRestartCount desc
```

**Use case:** CrashLoopBackOff detection. High restart count = degraded SLO.

---

## 6. CPU Usage per Node — performance baseline

```kusto
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "K8SNode"
| where CounterName == "cpuUsageNanoCores"
| summarize
    AvgCPU_cores = round(avg(CounterValue) / 1e9, 3),
    MaxCPU_cores = round(max(CounterValue) / 1e9, 3)
    by Computer, bin(TimeGenerated, 5m)
| order by TimeGenerated desc, Computer asc
```

**SRE note:** K3s-Homelab baseline: avg ~1.81%, max ~4.84% (from Container Insights)

---

## 7. Memory Usage per Node — capacity planning

```kusto
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "K8SNode"
| where CounterName == "memoryRssBytes"
| summarize
    AvgRAM_GB = round(avg(CounterValue) / 1073741824, 2),
    MaxRAM_GB = round(max(CounterValue) / 1073741824, 2)
    by Computer, bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

**SRE note:** K3s-Homelab baseline: avg 7.31%, max 14.48% of 16 GB worker nodes

---

## 8. Round-Robin Verification — load balancer proof

```kusto
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "GET /"
| extend Hostname = extract("Hostname: (k3s-[a-z0-9-]+)", 1, LogEntry)
| where isnotempty(Hostname)
| summarize RequestCount = count() by Hostname, bin(TimeGenerated, 1m)
| order by TimeGenerated desc
```

**Use case:** Proves Klipper LB distributes traffic across all 3 nodes evenly.

---

## 9. Azure Arc Agent Health — hybrid connectivity check

```kusto
KubePodInventory
| where TimeGenerated > ago(30m)
| where Namespace == "azure-arc"
| summarize arg_max(TimeGenerated, *) by Name
| project Name, PodStatus, PodRestartCount, ContainerLastStatus
| order by Name asc
```

**Expected:** 12 pods, all Running, RestartCount = 0

---

## 10. SLO Availability Calculation — 30-day rolling window

```kusto
KubeNodeInventory
| where TimeGenerated > ago(30d)
| summarize
    TotalSamples = count(),
    ReadySamples = countif(Status == "Ready")
    by Computer
| extend AvailabilityPct = round(toreal(ReadySamples) / toreal(TotalSamples) * 100, 3)
| project Computer, AvailabilityPct, ReadySamples, TotalSamples
| order by AvailabilityPct asc
```

**Use case:** Report SLO compliance to stakeholders. Target: >= 99.9% (43 min/month budget)

---

## Alert Rule — OOMKill (paste into Azure Monitor → Create alert)

```kusto
KubeEvents
| where Type == "Warning"
| where Reason == "OOMKilling"
| summarize OOMCount = count() by bin(TimeGenerated, 5m)
| where OOMCount > 0
```

- **Evaluation frequency:** 5 minutes
- **Window duration:** 15 minutes  
- **Threshold:** Count > 0
- **Severity:** 2 (Warning)
- **Action:** Email via SRE-Lab-Alerts action group
