# Monitoring Architecture – EKS Kubernetes Platform

## 1. Why Monitoring?

Monitoring is not an optional add-on in modern cloud-native systems. In Kubernetes-based platforms, monitoring is a **first-class architectural component** that provides:

* Visibility into infrastructure health (nodes, networking)
* Visibility into platform health (pods, scheduling, restarts)
* Visibility into application behavior (latency, errors)
* The foundation for alerting and incident response

Without monitoring, a system is effectively *running blind*.

---

## 2. Monitoring Philosophy in This Project

This project follows a **layered monitoring approach**, aligned with production best practices:

| Layer       | Purpose               | Example Signals                     |
| ----------- | --------------------- | ----------------------------------- |
| Node        | Infrastructure health | CPU, memory, disk, network          |
| Kubernetes  | Platform behavior     | Pod restarts, readiness, scheduling |
| Application | User-facing behavior  | Request latency, error rate         |

Each layer answers a different operational question:

* *Is the machine healthy?*
* *Is Kubernetes functioning correctly?*
* *Is the application delivering value to users?*

---

## 3. Why Prometheus?

Prometheus is the de‑facto standard monitoring system for Kubernetes because it is:

* Kubernetes‑native
* Pull‑based (better security model)
* Label‑driven (powerful querying)
* Widely adopted in production environments

Prometheus does **not replace application metrics**. Instead, it aggregates metrics from multiple layers into a single, queryable time‑series database.

---

## 4. Why Prometheus Operator (kube-prometheus-stack)?

Instead of managing Prometheus manually, this project uses **Prometheus Operator** via the `kube-prometheus-stack` Helm chart.

Benefits:

* Kubernetes‑native configuration via CRDs
* Automatic RBAC and ServiceAccount management
* Built‑in Alertmanager and Grafana integration
* Easier upgrades and long‑term maintainability

This reflects how monitoring is deployed in real production clusters.

---

## 5. Components Deployed by kube-prometheus-stack

The stack installs the following components:

* **Prometheus** – metrics collection and storage
* **Alertmanager** – alert routing and notification
* **Grafana** – metrics visualization
* **node-exporter** – node‑level metrics (DaemonSet)
* **kube-state-metrics** – Kubernetes object state metrics

All components run **inside the cluster** and communicate internally.

---

## 6. Metrics Collection Model

Prometheus uses **Kubernetes service discovery**:

* It watches the Kubernetes API Server
* Discovers nodes, pods, and services dynamically
* Scrapes metrics endpoints directly using internal networking

No static IPs are configured. Pod IP changes are handled automatically by Kubernetes metadata.

---

## 7. /health vs /metrics (Security Design)

The application exposes two endpoints:

| Endpoint   | Purpose                   | Exposure         |
| ---------- | ------------------------- | ---------------- |
| `/health`  | Liveness & readiness      | Public (via ALB) |
| `/metrics` | Detailed performance data | Internal only    |

### Why `/metrics` Is Not Public

* Prevents information disclosure
* Avoids abuse or scraping from the internet
* Metrics are intended **only** for Prometheus

Prometheus accesses `/metrics` internally without any Ingress exposure.

---

## 8. Authentication and RBAC Model

* Prometheus uses a Kubernetes ServiceAccount
* RBAC grants **read‑only access** to required resources
* No IAM roles are used for Prometheus itself
* No AWS credentials are stored or injected

RBAC ensures Prometheus:

* Can read metrics
* Cannot modify workloads or infrastructure

---

## 9. Alerting Strategy

Alerting is intentionally **minimal and meaningful** to avoid alert fatigue.

Planned alerts:

* **NodeNotReady** – infrastructure failure
* **PodCrashLoopBackOff** – application instability
* **HighRequestLatency** – degraded user experience

Alerts are routed via Alertmanager to external systems (e.g., Slack or email).

---

## 10. High Availability Considerations

For simplicity, Prometheus is deployed with a single replica in this project.

In production environments:

* Multiple Prometheus replicas are used
* Pod anti‑affinity is enabled
* Long‑term storage solutions may be added

These trade‑offs are documented intentionally to balance clarity and complexity.

---

## 11. CI/CD and Deployment Responsibility

Monitoring is deployed separately from application workloads:

* **deploy-infra / deploy-monitoring** workflows
* Cluster‑level permissions required
* Separation of concerns preserved

Application CI pipelines do **not** have permission to modify monitoring or RBAC.

---

## 12. Summary

This monitoring architecture:

* Mirrors real‑world production designs
* Enforces strong security boundaries
* Separates platform and application responsibilities
* Demonstrates operational maturity beyond basic deployments

It completes the platform by adding **observability**, which is essential for operating Kubernetes systems reliably.
