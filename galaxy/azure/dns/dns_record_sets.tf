# ── DNS Record Sets ───────────────────────────────────────────────────────────

variable "azure_dns_record_sets" {
  type = map(object({
    subscription_id     = optional(string)
    resource_group_name = string
    zone_name           = string
    record_name         = string
    record_type         = string
    ttl                 = optional(number, 3600)
    txt_records = optional(list(object({
      value = list(string)
    })), null)
    cname_record = optional(object({
      cname = string
    }), null)
    mx_records = optional(list(object({
      preference = number
      exchange   = string
    })), null)
    a_records = optional(list(object({
      ipv4Address = string
    })), null)
    aaaa_records = optional(list(object({
      ipv6Address = string
    })), null)
    metadata = optional(map(string), null)
  }))
  description = <<-EOT
    Map of Azure DNS record sets to create.

    Example:
      azure_dns_record_sets = {
        spf = {
          resource_group_name = "rg-dns"
          zone_name           = "contoso.com"
          record_name         = "@"
          record_type         = "TXT"
          ttl                 = 3600
          txt_records         = [{ value = ["v=spf1 include:spf.protection.outlook.com -all"] }]
        }
      }
  EOT
  default     = {}
}

locals {
  azure_dns_record_sets = provider::rest::resolve_map(
    local._ctx_l2,
    merge(try(local._yaml_raw.azure_dns_record_sets, {}), var.azure_dns_record_sets)
  )
  _drs_ctx = provider::rest::merge_with_outputs(local.azure_dns_record_sets, module.azure_dns_record_sets)
}

module "azure_dns_record_sets" {
  source   = "./modules/azure/dns_record_set"
  for_each = local.azure_dns_record_sets

  depends_on = [module.azure_dns_zones, module.azure_email_communication_service_domains]

  subscription_id     = try(each.value.subscription_id, var.subscription_id)
  resource_group_name = each.value.resource_group_name
  zone_name           = each.value.zone_name
  record_name         = each.value.record_name
  record_type         = each.value.record_type
  ttl                 = try(each.value.ttl, 3600)
  txt_records         = try(each.value.txt_records, null)
  cname_record        = try(each.value.cname_record, null)
  mx_records          = try(each.value.mx_records, null)
  a_records           = try(each.value.a_records, null)
  aaaa_records        = try(each.value.aaaa_records, null)
  metadata            = try(each.value.metadata, null)
  check_existance     = var.check_existance
}
