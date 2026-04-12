locals {
  _k8s_values = { for k, v in {
    k8s_kind_clusters         = module.k8s_kind_clusters
    k8s_namespaces            = module.k8s_namespaces
    k8s_cluster_role_bindings = module.k8s_cluster_role_bindings
    k8s_deployments           = module.k8s_deployments
    k8s_jobs                  = module.k8s_jobs
    k8s_config_maps           = module.k8s_config_maps
  } : k => v if length(v) > 0 }
}

output "k8s_values" {
  description = "Map of all K8s module outputs, keyed by the same keys as var.*. Empty maps are filtered out."
  value       = length(local._k8s_values) > 0 ? local._k8s_values : null
  sensitive   = true
}
