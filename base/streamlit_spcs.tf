######################################
## Streamlit on Snowpark Containers ##
######################################
# Streamlit apps run as SPCS services with caller's rights enabled.
# The container image must be pushed to the image repository outside Terraform.
# Caller grants (GRANT CALLER ... TO ROLE <service owner>) are not supported by the provider,
# manage them with Permifrost or SQL to restrict what the app can do on behalf of the caller.

locals {
  spcs_apps = { for app in var.snowflake_streamlit_spcs_apps : app.name => app }
}

resource "snowflake_compute_pool" "streamlit" {
  provider = snowflake.accountadmin
  for_each = local.spcs_apps

  name                = "STREAMLIT_${each.key}_POOL"
  instance_family     = each.value.instance_family
  min_nodes           = 1
  max_nodes           = each.value.max_nodes
  auto_resume         = true
  initially_suspended = true
  auto_suspend_secs   = each.value.auto_suspend_secs
  comment             = "Compute pool for Streamlit app ${each.key}"
}

resource "snowflake_image_repository" "streamlit" {
  provider = snowflake.sysadmin
  for_each = local.spcs_apps

  name     = "STREAMLIT_${each.key}_REPO"
  database = each.value.database
  schema   = each.value.schema
  comment  = "Image repository for Streamlit app ${each.key}"
}

# Optional egress (e.g. pip, external APIs). Only created when egress hosts are listed.
resource "snowflake_network_rule" "streamlit_egress" {
  provider = snowflake.sysadmin
  for_each = { for k, app in local.spcs_apps : k => app if length(app.egress_hosts) > 0 }

  name       = "STREAMLIT_${each.key}_EGRESS"
  database   = each.value.database
  schema     = each.value.schema
  type       = "HOST_PORT"
  mode       = "EGRESS"
  value_list = each.value.egress_hosts
}

resource "snowflake_external_access_integration" "streamlit" {
  provider = snowflake.accountadmin
  for_each = snowflake_network_rule.streamlit_egress

  name                  = "STREAMLIT_${each.key}_EAI"
  enabled               = true
  allowed_network_rules = [each.value.fully_qualified_name]
}

resource "snowflake_service" "streamlit" {
  provider = snowflake.sysadmin
  for_each = local.spcs_apps

  name            = "STREAMLIT_${each.key}"
  database        = each.value.database
  schema          = each.value.schema
  in_compute_pool = snowflake_compute_pool.streamlit[each.key].fully_qualified_name
  query_warehouse = each.value.query_warehouse
  auto_resume     = true
  external_access_integrations = (
    contains(keys(snowflake_external_access_integration.streamlit), each.key)
    ? [snowflake_external_access_integration.streamlit[each.key].name] : []
  )

  from_specification {
    text = yamlencode({
      spec = {
        containers = [{
          name = "streamlit"
          # /<db>/<schema>/<repo>/<image>:<tag>
          image = "/${each.value.database}/${each.value.schema}/${snowflake_image_repository.streamlit[each.key].name}/${each.value.image}"
        }]
        endpoints = [{
          name   = "app"
          port   = each.value.port
          public = true
        }]
        # Grant per role: GRANT SERVICE ROLE <service>!APP_USER TO ROLE <role>
        serviceRoles = [{
          name      = "app_user"
          endpoints = ["app"]
        }]
      }
      capabilities = {
        securityContext = {
          executeAsCaller = true # caller's rights: Sf-Context-Current-User-Token header on ingress
        }
      }
    })
  }

  comment = "Streamlit app ${each.key} (caller's rights)"
}

# NOTE: the public ingress URL is shown by SHOW ENDPOINTS IN SERVICE (column ingress_url).
output "streamlit_spcs_services" {
  description = "Fully qualified name of the Streamlit SPCS services"
  value       = { for k, s in snowflake_service.streamlit : k => s.fully_qualified_name }
}
