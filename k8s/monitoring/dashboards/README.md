# Grafana Dashboard – Application Monitoring Design

## Purpose of the Dashboard

This dashboard is designed to answer a single core question:

> **Is the application delivering a good user experience right now?**

It intentionally avoids infrastructure-level noise and focuses on **application-facing signals** that matter to users and operators.

---

## Design Principles

The dashboard follows four key principles:

1. **User-centric metrics** – what the user feels
2. **Minimal but sufficient** – no metric overload
3. **Correlation-friendly** – panels can be read together
4. **Action-oriented** – every panel helps a decision

---

## Dashboard Sections

### 1. Traffic Overview

**Purpose:** Understand current load and traffic patterns.

**Panels:**

* Requests per second (RPS)
* Requests per pod

**Why this matters:**

* Confirms whether the system is under normal or abnormal load
* Helps correlate latency or errors with traffic spikes

---

### 2. Latency (User Experience)

**Purpose:** Measure how fast users receive responses.

**Panels:**

* P50 latency (median)
* P95 latency (tail latency)

**Why P95 matters more than average:**

* Averages hide slow users
* Tail latency reflects real experience

**SLO alignment:**

* Directly tied to `HighRequestLatency` alert

---

### 3. Error Rate

**Purpose:** Detect failing requests that impact users.

**Panels:**

* HTTP 5xx error rate
* Error percentage over total requests

**Why this matters:**

* Application can be "up" but failing
* Errors often precede outages

---

### 4. Pod Health & Stability

**Purpose:** Verify that the application is stable at runtime.

**Panels:**

* Pod restart count
* Number of running pods

**Why this matters:**

* Restarts often indicate bugs or resource pressure
* Correlates directly with `PodCrashLoopBackOff` alert

---

### 5. Resource Utilization (Context Only)

**Purpose:** Provide context without over-focusing on infrastructure.

**Panels:**

* CPU usage per pod
* Memory usage per pod

**Why included but de-emphasized:**

* Resource metrics explain *why* latency or crashes occur
* They are not primary user-facing signals

---

## Metrics Sources

| Metric Type             | Source                 |
| ----------------------- | ---------------------- |
| Request count / latency | Application `/metrics` |
| Pod status              | kube-state-metrics     |
| Resource usage          | cAdvisor / kubelet     |

Prometheus aggregates all sources into a unified query layer.

---

## What This Dashboard Deliberately Excludes

* Node-level metrics (covered by infra dashboards)
* Kubernetes control-plane internals
* Debug-only metrics

This separation prevents cognitive overload during incidents.

---

## Production Readiness Considerations

In production environments, this dashboard could be extended with:

* SLO burn-rate panels
* Deployment markers
* Canary vs stable comparisons

These are intentionally excluded to keep the project focused and readable.

---

## Summary

This dashboard demonstrates:

* Clear understanding of observability goals
* Separation between platform and application concerns
* Alignment between metrics, alerts, and user experience

It complements Prometheus alerts by providing **visual confirmation and context** during incidents.
