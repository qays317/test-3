“TLS termination was intentionally omitted as it was already demonstrated in a previous HA WordPress project using CloudFront and multi-ALB ACM certificates.”


“The application itself is intentionally simple.
The goal of the project is to demonstrate Kubernetes operations, observability, scaling behavior, and failure handling — not application complexity.”



“Each GitHub Actions job runs in an isolated environment, so kubeconfig must be generated in every workflow that interacts with the cluster.”



Second GitHub workflow (deploy-app.yml):
GitHub Actions
  ↓ (OIDC)
IAM Role (app-deploy-ci-role)
  ↓ (aws-auth mapping)
Kubernetes User = github-actions
  ↓ (RBAC)
Role (namespace-scoped, limited)
  ↓
kubectl apply works





RBAC:

## CI/CD Security Model

- GitHub Actions uses OIDC with AWS IAM roles.
- Infrastructure and application delivery are separated.
- Application pipeline is restricted via Kubernetes RBAC (no cluster-admin).

“I mapped the GitHub Actions IAM role to a dedicated Kubernetes group and bound it to a namespace-scoped Role with only deployment-related permissions.”

What can GitHub action do?
✔ kubectl apply -f deployment.yaml
✔ kubectl apply -f service.yaml
✔ kubectl apply -f ingress.yaml

❌ kubectl delete namespace default
❌ kubectl get nodes
❌ kubectl edit aws-auth
❌ kubectl apply CRDs

“I explicitly avoided using cluster-admin.
I mapped the GitHub Actions IAM role to a dedicated Kubernetes group and bound it to a namespace-scoped Role with minimal permissions required for application delivery.”






Prometheus

Prometheus discovers targets via Kubernetes API,
but scrapes metrics directly from HTTP endpoints exposed by each component.

“Persistent storage is intentionally omitted in this project to keep the focus on architecture, security, and observability design. In production, Prometheus would be backed by persistent volumes or long-term storage solutions such as Thanos.”

“We use Prometheus Operator because Kubernetes is declarative and dynamic, and Operator keeps Prometheus configuration in sync with cluster state.”