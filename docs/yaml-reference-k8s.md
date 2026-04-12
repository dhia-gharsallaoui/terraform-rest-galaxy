# YAML Reference — Kubernetes

← [Back to index](yaml-reference.md)

### `k8s_cluster_role_bindings`

**API version:** `Kubernetes RBAC API v1`

Map of Kubernetes ClusterRoleBindings to create via the K8s REST API.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `role_ref` | `object` | yes | — |  |
| `subjects` | `list(object)` | yes | — |  |
| `labels` | `map(string)` | no | `{}` |  |

#### YAML Example

```yaml
k8s_cluster_role_bindings:
  admin_binding:
    cluster: "ref:k8s_kind_clusters.platform.name"
    name: "entra-id-admins"
    role_ref:
      kind: "ClusterRole"
      name: "cluster-admin"
    subjects: [{ kind = "Group", name = "00000000-..." }]
```

---

### `k8s_config_maps`

**API version:** `Kubernetes API v1`

Map of Kubernetes ConfigMaps to create via the K8s REST API.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `namespace` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `data` | `map(string)` | no | `{}` |  |
| `labels` | `map(string)` | no | `{}` |  |

#### YAML Example

```yaml
k8s_config_maps:
  app_config:
    cluster: "ref:k8s_kind_clusters.platform.name"
    namespace: "ref:k8s_namespaces.workloads.name"
    name: "app-settings"
    data:
      LOG_LEVEL: "info"
```

---

### `k8s_deployments`

**API version:** `Kubernetes Apps API v1`

Map of Kubernetes Deployments to create via the K8s REST API.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `namespace` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `image` | `string` | yes | — |  |
| `replicas` | `number` | no | `1` |  |
| `labels` | `map(string)` | no | `{}` |  |
| `node_selector` | `map(string)` | no | `{}` |  |
| `tolerations` | `list(object)` | no | `[]` |  |
| `container_port` | `number` | no | `null` |  |
| `env` | `map(string)` | no | `{}` |  |
| `service_account_name` | `string` | no | `null` |  |
| `pod_labels` | `map(string)` | no | `{}` |  |
| `command` | `list(string)` | no | `null` |  |
| `args` | `list(string)` | no | `null` |  |

#### YAML Example

```yaml
k8s_deployments:
  nginx:
    cluster: "ref:k8s_kind_clusters.platform.name"
    namespace: "ref:k8s_namespaces.workloads.name"
    name: "nginx"
    image: "nginx:latest"
    replicas: 2
```

---

### `helm_releases`

Map of Helm releases to install on Kubernetes clusters.
The 'cluster' field references a k8s_kind_clusters key name to determine
which kube context to use (derived as "kind-<cluster_name>").

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `namespace` | `string` | no | `"default"` |  |
| `chart` | `string` | yes | — |  |
| `repository` | `string` | no | `null` |  |
| `chart_version` | `string` | no | `null` |  |
| `values` | `string` | no | `null` |  |
| `set` | `map(string)` | no | `{}` |  |
| `set_sensitive` | `map(string)` | no | `{}` |  |
| `kubeconfig_path` | `string` | no | `null` |  |
| `kube_context` | `string` | no | `null` |  |
| `create_namespace` | `bool` | no | `true` |  |
| `wait` | `bool` | no | `true` |  |
| `timeout` | `number` | no | `600` |  |
| `insecure_skip_tls_verify` | `bool` | no | `false` |  |
| `_tls_key_refs` | `map(string)` | no | `{}` |  |

#### YAML Example

```yaml
helm_releases:
  arc_agent_platform:
    cluster: "ref:k8s_kind_clusters.platform.name"
    name: "azure-arc"
    namespace: "azure-arc"
    chart: "azure-arc"
    repository: "https://azurearcfork8s.azurecr.io/helm/v1/repo"
    set:
      "global.subscriptionId": "00000000-..."
      "global.resourceGroupName": "rg-arc"
      "global.clusterName": "platform-cluster"
```

---

### `k8s_jobs`

**API version:** `Kubernetes Batch API v1`

Map of Kubernetes Jobs to create via the K8s REST API.
Jobs run to completion — Terraform waits until the Job succeeds (or fails).
Use for post-deployment verification tests.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `namespace` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `image` | `string` | yes | — |  |
| `backoff_limit` | `number` | no | `0` |  |
| `labels` | `map(string)` | no | `{}` |  |
| `pod_labels` | `map(string)` | no | `{}` |  |
| `env` | `map(string)` | no | `{}` |  |
| `service_account_name` | `string` | no | `null` |  |
| `command` | `list(string)` | no | `null` |  |
| `args` | `list(string)` | no | `null` |  |

#### YAML Example

```yaml
k8s_jobs:
  e2e_postgres:
    cluster: "aks-regulated-001"
    namespace: "ref:k8s_namespaces.test_app.name"
    name: "e2e-postgres-test"
    image: "mcr.microsoft.com/azure-cli:2.84.0"
    command: ["/bin/bash", "-c"]
    args: ["echo OK"]
```

---

### `k8s_kind_clusters`

**API version:** `tehcyx/kind provider`

Map of kind clusters to create locally. Each map key acts as the for_each
identifier and must be unique within this configuration.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `name` | `string` | yes | — |  |
| `kubernetes_version` | `string` | yes | — |  |
| `networking` | `object` | no | `{}` |  |
| `node_pools` | `map(object)` | no | `{}` |  |

#### YAML Example

```yaml
k8s_kind_clusters:
  platform:
    name: "platform-cluster"
    kubernetes_version: "1.30.2"
    node_pools:
      control_plane:
        role: "control-plane"
        count: 1
      workers:
        role: "worker"
        count: 3
```

---

### `k8s_namespaces`

**API version:** `Kubernetes API v1`

Map of Kubernetes namespaces to create via the K8s REST API.
The 'cluster' field references a k8s_kind_clusters key name to determine
which kube-apiserver to target.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `labels` | `map(string)` | no | `{}` |  |
| `annotations` | `map(string)` | no | `{}` |  |

#### YAML Example

```yaml
k8s_namespaces:
  monitoring:
    cluster: "ref:k8s_kind_clusters.platform.name"
    name: "monitoring"
    labels:
      managed-by: "terraform-rest"
```

---

### `k8s_service_accounts`

**API version:** `Kubernetes API v1`

Map of Kubernetes ServiceAccounts to create via the K8s REST API.
The 'cluster' field references a cluster name to determine
which kube-apiserver to target.

#### Attributes

| Name | Type | Required | Default | Description |
|------|------|:--------:|---------|-------------|
| `cluster` | `string` | yes | — |  |
| `namespace` | `string` | yes | — |  |
| `name` | `string` | yes | — |  |
| `labels` | `map(string)` | no | `{}` |  |
| `annotations` | `map(string)` | no | `{}` |  |

#### YAML Example

```yaml
k8s_service_accounts:
  my_app:
    cluster: "aks-regulated-001"
    namespace: "ref:k8s_namespaces.my_app.name"
    name: "my-app-sa"
    annotations:
      "azure.workload.identity/client-id": "..."
    labels:
      "azure.workload.identity/use": "true"
```

---
