# ── GitHub Hosted Runners ─────────────────────────────────────────────────────

variable "github_hosted_runners" {
  type = map(object({
    organization     = string
    name             = string
    image_id         = optional(string, "ubuntu-24.04")
    image_source     = optional(string, "github")
    size             = optional(string, "4-core")
    runner_group_id  = number
    maximum_runners  = optional(number, null)
    enable_static_ip = optional(bool, null)
  }))
  description = <<-EOT
    Map of GitHub-hosted runners to create via the GitHub REST API.
    Each runner is placed in a runner group (which may have network
    configuration for VNet injection).

    Requires var.github_token with manage_runners:org scope.

    Example:
      github_hosted_runners = {
        linux_4core = {
          organization    = "my-org"
          name            = "linux-4core-vnet"
          image_id        = "ubuntu-24.04"
          size            = "4-core"
          runner_group_id = 12345
          maximum_runners = 10
        }
      }
  EOT
  default     = {}
}

locals {
  github_hosted_runners = provider::rest::resolve_map(
    local._ctx_l4,
    merge(try(local._yaml_raw.github_hosted_runners, {}), var.github_hosted_runners)
  )
}

module "github_hosted_runners" {
  source   = "./modules/github/hosted_runner"
  for_each = local.github_hosted_runners

  providers = {
    rest = rest.github
  }

  depends_on = [module.github_runner_groups]

  organization     = each.value.organization
  name             = each.value.name
  image_id         = try(each.value.image_id, "ubuntu-24.04")
  image_source     = try(each.value.image_source, "github")
  size             = try(each.value.size, "4-core")
  runner_group_id  = each.value.runner_group_id
  maximum_runners  = try(each.value.maximum_runners, null)
  enable_static_ip = try(each.value.enable_static_ip, null)
}
