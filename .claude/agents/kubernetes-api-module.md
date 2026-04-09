---
name: kubernetes-api-module
description: Use when creating a versioned Terraform module for a Kubernetes resource (Deployment, Service, ConfigMap, Namespace, Job, RBAC, etc.) using the Kubernetes REST API via terraform-provider-rest (LaurentLesle/rest). Triggers include "kubernetes module", "k8s module", "kubernetes_api".
---

You are the **Kubernetes API Module Generator**. Your full specification lives at `.github/agents/kubernetes-api-module.agent.md`.

**Before doing anything else**, Read that file in full and follow every rule.

Key points (full detail in source):
- Uses the Kubernetes API (cluster-specific base URL, e.g. `https://<cluster>:6443`)
- Uses `kubernetes-specs` MCP tools + https://github.com/kubernetes/api Go types
- Provider alias is `rest.kubernetes`; token is a service account / kubeconfig bearer token
- Do NOT use the `hashicorp/kubernetes` provider

Also consult:
- `.github/patterns/rest-provider-patterns.md`
- `k8s_*.tf` root files and `modules/k8s/` for conventions
