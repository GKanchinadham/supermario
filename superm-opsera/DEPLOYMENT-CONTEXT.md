# Deployment Context

## Identifiers
- **Tenant**: superm
- **App Identifier**: superm
- **Environment**: dev
- **Branch/Folder**: superm-opsera
- **ArgoCD Folder**: superm-opsera/argocd/

## GitOps Architecture
- **Pattern**: greenfield
- **ArgoCD**: CREATE NEW
- **Workload Cluster**: CREATE NEW

## Resource Names
- **ArgoCD App**: superm-argo-dev
- **Namespace**: superm-dev
- **ECR Backend**: superm-backend
- **VPC**: superm-vpc
- **ArgoCD Cluster**: superm-argocd
- **Workload Cluster**: superm-workload-dev

## AWS Configuration
- **Region**: eu-west-2 (used for EKS, ECR, and ACM - keep consistent!)
- **Account ID**: (will be detected during deployment)
- **EKS Cluster**: superm-argocd / superm-workload-dev

## Resource Tags (apply to ALL cloud resources)
```
app-identifier: superm
environment: dev
deployment-name: superm-opsera
gitops-pattern: greenfield
managed-by: opsera-gitops
created-by: claude-code
tenant: superm
```

## Endpoints (after deployment)
- **URL**: https://superm-dev.agents.opsera-labs.com

## Pattern-Specific Checklist

### Greenfield Pattern Steps:
- [ ] Create VPC with public/private subnets (Terraform)
- [ ] Create ArgoCD management cluster (Terraform)
- [ ] Create workload cluster (Terraform)
- [ ] Install ArgoCD on management cluster
- [ ] Register workload cluster with ArgoCD
- [ ] Install ExternalDNS on workload cluster
- [ ] Create ECR repositories

## Common Steps (All Patterns):
- [ ] Branch created
- [ ] Folder structure created
- [ ] Initial commit pushed
- [ ] ECR repositories created (tagged)
- [ ] Namespace created (labeled)
- [ ] ArgoCD application created: superm-argo-dev
- [ ] Deployment verified

---
Created: 2026-01-07

