# Prometheus Alerts – Design & Preparation

This document defines the alerting strategy and example PrometheusRule objects for the Kubernetes platform.

---

## Alerting Philosophy

Alerts are designed to be:

* **Actionable** (someone can do something about them)
* **Layered** (infrastructure, platform, application)
* **Minimal** (avoid alert fatigue)

The goal is not to alert on every anomaly, but to alert when **user experience or system reliability is at risk**.

---

## Alert Layers

| Layer       | What It Protects      | Why It Matters                   |
| ----------- | --------------------- | -------------------------------- |
| Node        | EC2 / Worker health   | Losing capacity breaks workloads |
| Pod         | Application stability | Crashes affect availability      |
| Application | User experience       | Latency/errors impact users      |

---

## Alert 1: NodeNotReady

**Purpose:** Detect when a Kubernetes worker node becomes unavailable.

**Why this alert exists:**

* Indicates infrastructure failure
* Capacity loss may lead to pod eviction or scheduling failures

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: node-not-ready
  namespace: monitoring
spec:
  groups:
    - name: node.rules
      rules:
        - alert: NodeNotReady
          expr: |
            kube_node_status_condition{condition="Ready",status="true"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Node is not Ready"
            description: "Kubernetes node has been in NotReady state for more than 5 minutes."
```

---

## Alert 2: PodCrashLoopBackOff

**Purpose:** Detect unstable application behavior caused by repeated crashes.

**Why this alert exists:**

* Indicates bugs, misconfiguration, or dependency failures
* Directly affects service availability

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: pod-crashloop
  namespace: monitoring
spec:
  groups:
    - name: pod.rules
      rules:
        - alert: PodCrashLoopBackOff
          expr: |
            kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} > 0
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: "Pod is crash looping"
            description: "Pod has been in CrashLoopBackOff state for more than 2 minutes."
```

---

## Alert 3: HighRequestLatency (Application Level)

**Purpose:** Detect degraded user experience due to slow responses.

**Why this alert exists:**

* Application may still be up but unusable
* Protects user-facing SLOs

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app-latency
  namespace: monitoring
spec:
  groups:
    - name: app.rules
      rules:
        - alert: HighRequestLatency
          expr: |
            histogram_quantile(0.95,
              rate(http_request_duration_seconds_bucket[5m])
            ) > 1
          for: 3m
          labels:
            severity: warning
          annotations:
            summary: "High application latency"
            description: "95th percentile latency is above 1s for more than 3 minutes."
```

---

## Why Only These Alerts?

* **NodeNotReady** covers infrastructure failures
* **PodCrashLoopBackOff** covers platform/application instability
* **HighRequestLatency** covers user experience

This provides strong coverage without alert fatigue.

---

## Production Considerations

In production environments, additional alerts may be added for:

* Disk pressure
* Memory saturation
* API server latency
* SLO burn rates

These are intentionally excluded here to keep the project focused and readable.

---

## Summary

This alert set demonstrates:

* Understanding of alert layering
* Awareness of operational impact
* Mature alerting design choices

Alerts are designed to notify **only when action is required**, which is a core principle of effective monitoring.
