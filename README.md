# Kubernetes Platform on AWS (EKS)

## Overview

This project demonstrates the design and deployment of a production-style Kubernetes platform on AWS EKS, focusing on:
  - Infrastructure as Code (Terraform)
  - Secure CI/CD using GitHub Actions + OIDC
  - Clear separation of responsibilities (infra / app / monitoring)
  - Kubernetes-native application deployment
  - Observability with Prometheus, Alertmanager, and Grafana
  - Minimal but meaningful alerting focused on user experience

The goal of this project is architectural clarity and operational correctness, not feature overload.

---

## High-Level Architecture

The platform consists of the following layers:

### AWS Infrastructure

  - VPC with public and private subnets
  - Internet Gateway + NAT Gateway
  - EKS Cluster (managed control plane)
  - EKS Node Group (EC2 worker nodes)

### Kubernetes Platform

  - Application deployed via Deployment / Service / Ingress
  - AWS Load Balancer Controller for ALB integration
  - RBAC enforcing least privilege

### CI/CD

  - GitHub Actions with OIDC (no static credentials)
  - Separate workflows for infra, app, and monitoring

### Monitoring

  - Prometheus (metrics collection)
  - Alertmanager (alert routing)
  - Grafana (visualization)
  - kube-prometheus-stack via Helm

Prometheus Operator continuously reconciles Prometheus configuration with cluster state, eliminating manual target management and static configuration.

---

## CI/CD Design

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐
|Workflows           	  |  Responsibility                                |  IAM Role                       |
|───────────────────────|────────────────────────────────────────────────|─────────────────────────────────|
|deploy-infra.yml	      |  Provision infrastructure & bootstrap cluster	 |  kubernetes-ci-infra-role       |
|deploy-app.yml	        |  Deploy application resources	                 |  kubernetes-ci-app-role         |
|deploy-monitoring.yml  |  Deploy monitoring stack	                     |  kubernetes-ci-monitoring-role  |
└──────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Each workflow:

  - Uses GitHub OIDC to assume an IAM role
  - Generates a temporary kubeconfig
  - Operates only within its allowed scope

No credentials or kubeconfig files are stored in the repository.

---

## Security Model

### IAM → Kubernetes Mapping

  - AWS IAM roles are mapped to Kubernetes users/groups using the aws-auth ConfigMap
  - Kubernetes does not understand IAM directly
  - Authorization is enforced using RBAC

### Separation of Concerns

  - Infra role: bootstrap access only, used once
  - App role: can manage Deployments, Services, Ingresses (namespace-scoped)
  - Monitoring role: can install Helm charts and monitoring CRDs

No workflow has unnecessary cluster-admin privileges.

---

## Application Deployment

The application is deployed using standard Kubernetes primitives:

* Deployment: manages pod replicas
* Service (ClusterIP): internal load balancing
* Ingress (ALB): external HTTP access

Endpoints:

* /health – exposed publicly via ALB
* /metrics – internal only, consumed by Prometheus

This design prevents metrics exposure to the public internet

---

## Monitoring Architecture

Monitoring is deployed using kube-prometheus-stack (Prometheus Operator).

Components

  - Prometheus – scrapes metrics
  - Alertmanager – handles alerts
  - Grafana – dashboards
  - node-exporter – node-level metrics
  - kube-state-metrics – Kubernetes object state

All components run inside the cluster.

Grafana is accessed via kubectl port-forward, not Ingress

---

## Alerting Strategy

This project intentionally defines a single alert:

HighRequestLatency

  - Purpose: Detect degraded user experience caused by slow responses.
  - Logic: Alert when the 95th percentile request latency exceeds 1 second for more than 3 minutes

```yaml
histogram_quantile(
  0.95,
  rate(http_request_duration_seconds_bucket[5m])
) > 1
```

Thresholds are intentionally conservative to avoid alerting on transient spikes.

---

## Deployment Order (Execution Plan)

1. deploy-infra

    - Provision AWS infrastructure
    - Create EKS cluster and node group
    - Configure aws-auth and RBAC

2. deploy-app

   - Deploy application (Deployment, Service, Ingress)

3. deploy-monitoring

    - Install monitoring stack via Helm
    - Apply ServiceMonitors and alert rules

Deployment is intentionally planned to run once, not iteratively

---

## What This Project Demonstrates

* Real-world EKS platform design
* Secure CI/CD with GitHub Actions + OIDC
* Practical Kubernetes RBAC usage
* Thoughtful monitoring and alerting
* Senior-level architectural reasoning

---

## Diagram

### High Level Architecture
```text
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                   GitHub Actions                                      │
│                                                                                       │
│    ┌───────────────┐            ┌────────────────┐            ┌──────────────┐        │ 
│    │ deploy-infra  │            │ deploy-app     │            │ deploy-mon   │        │
│    │ (Terraform)   │            │ (kubectl)      │            │ (Helm)       │        │
│    └───────┬───────┘            └───────┬────────┘            └───────┬──────┘        │
│            │                            │                             │               │
│     Assume IAM role              Assume IAM role               Assume IAM role        │
|(kubernetes-ci-infra-role)    (kubernetes-ci-app-role)  (kubernetes-ci-monitoring-role)|
│            │                            │                             │               │
└────────────┼────────────────────────────┼─────────────────────────────┼───────────────┘
             │                            │                             │
             ▼                            ▼                             ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS Account                                        │
│                                                                                       │
│             ┌───────────────────────────────────────────────────────┐                 │
│             │                          VPC                          │                 │
│             │                                                       │                 │
│             │  ┌──────────────┐                   ┌──────────────┐  │                 │
│             │  │ Public Subnet│                   │ PrivateSubnet│  │                 │
│             │  │              │                   │              │  │                 │
│             │  │  ALB         │                   │  EKS Nodes   │  │                 │
│             │  │  (Ingress)   │                   │              │  │                 │
│             │  └──────┬───────┘                   └──────┬───────┘  │                 │
│             │         │                                  │          │                 │
│             │         ▼                                  ▼          │                 │
│             │   Internet Users                    Kubernetes Pods   │                 │
│             │                                                       │                 │
│             └───────────────────────────────────────────────────────┘                 │
│                                                                                       │
│             ┌───────────────────────────────────────────────────────┐                 │
│             │                  EKS Control Plane                    │                 │
│             │   (API Server – Managed by AWS)                       │                 │
│             └───────────────────────────────────────────────────────┘                 │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### Application Data Flow
```text
User Browser
     │
     ▼
AWS ALB (Ingress Controller)
     │
     ▼
Kubernetes Service
     │
     ▼
Application Pods (Flask)
     │
     ├── /health   (public via ALB)
     └── /metrics  (internal only)
```

### Monitoring Data Flow
```text
Application Pod
   └── exposes /metrics
           │
           ▼
Prometheus (inside cluster)
           │
           ▼
Alertmanager
           │
           ▼
Slack / Notification

Grafana
   ▲
   │ queries
   │
Prometheus
```

No Ingress for Prometheus / Grafana
Grafana accessed via kubectl port-forward

### Control Plane & Auth Flow
```text
kubectl / helm
     │
     │ aws eks update-kubeconfig
     ▼
EKS API Server
     │
     │ verifies IAM token (STS)
     ▼
aws-auth ConfigMap
     │
     │ maps IAM → Kubernetes groups
     ▼
RBAC (Role / ClusterRole)
     │
     ▼
Allowed / Denied action
```

### CI/CD Responsibility Boundaries
```text
┌──────────────────────────────┐
│ deploy-infra.yml             │
│ IAM: kubernetes-ci-infra     │
│                              │
│ - Terraform                  │
│ - EKS cluster                │
│ - Node groups                │
│ - aws-auth                   │
│ - RBAC                       │
│ (bootstrap admin only)       │
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│ deploy-app.yml               │
│ IAM: kubernetes-ci-app       │
│                              │
│ - Deployment                 │
│ - Service                    │
│ - Ingress                    │
│ (NO cluster-admin)           │
└─────────────┬────────────────┘
              │
              ▼
┌──────────────────────────────┐
│ deploy-monitoring.yml        │
│ IAM: kubernetes-ci-monitoring│
│                              │
│ - Helm install monitoring    │
│ - ServiceMonitors            │
│ - Alerts                     │
│ (monitoring scope only)      │
└──────────────────────────────┘
```

### Second GitHub workflow (deploy-app.yml):
```text
GitHub Actions
  ↓ (OIDC)
IAM Role (app-deploy-ci-role)
  ↓ (aws-auth mapping)
Kubernetes User = github-actions
  ↓ (RBAC)
Role (namespace-scoped, limited)
  ↓
kubectl apply works
``` 

---

## Notes

* TLS termination was intentionally omitted as it was already demonstrated in a previous HA WordPress project using CloudFront and multi-ALB ACM certificates.
* The application itself is intentionally simple. The goal of the project is to demonstrate Kubernetes operations, observability, scaling behavior, and failure handling — not application complexity.
* Persistent storage is intentionally omitted in this project to keep the focus on architecture, security, and observability design. In production, Prometheus would be backed by persistent volumes or long-term storage solutions such as Thanos.
* Why the monitoring CI role needs cluster-admin

  The deploy-monitoring workflow uses Helm to install kube-prometheus-stack (Prometheus Operator + CRDs + Grafana + Alertmanager).
Helm does not only “deploy Prometheus pods”. During an install/upgrade it performs Kubernetes API operations such as:
    - listing/creating/updating Secrets (release state stored as Secrets, and chart resources may also create Secrets)
    - creating/updating ConfigMaps
    - creating CustomResourceDefinitions (CRDs) and cluster-scoped resources
    - creating RBAC objects (ServiceAccounts / Roles / ClusterRoles / Bindings)
    - installing webhooks and other components that operate cluster-wide

  Because of that, giving the monitoring workflow only “read-only monitoring permissions” is not enough — Helm itself needs broad permissions, especially on secrets inside the monitoring namespace, and often cluster-scoped rights for CRDs.
For this project, the monitoring pipeline is intentionally granted cluster-admin, but it is isolated in its own IAM role + Kubernetes group, separate from the application deploy workflow.
This keeps the application workflow least-privileged while allowing monitoring to be installed correctly
* Root Cause Analysis – ALB Creation Failure

  The AWS Load Balancer Controller relies on IRSA (IAM Roles for Service Accounts).
After rebuilding the EKS cluster, the OIDC provider ID changed.
  The IAM role trust policy for the controller was still referencing the old OIDC provider ARN, causing STS to reject AssumeRoleWithWebIdentity.

  Although Kubernetes resources (Ingress, Service, Pods) were valid, AWS rejected all ELB API calls, preventing ALB creation.

  The issue was resolved by dynamically referencing the cluster OIDC provider using Terraform data sources instead of hardcoding the ARN.
---

