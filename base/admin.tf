resource "snowflake_database" "system_database" {
  provider = snowflake.sysadmin
  count    = var.snowflake_admin_setup ? 1 : 0

  name                        = "SYSTEM"
  comment                     = "The database containing project dataproducts"
  data_retention_time_in_days = var.default_dds_retention_time
}

######################
## ROLES AND GRANTS ##
#####################

resource "snowflake_account_role" "ar_system_database_r" {
  provider = snowflake.useradmin
  count    = var.snowflake_admin_setup ? 1 : 0
  name     = "AR_DB_SYSTEM_R"
}
resource "snowflake_account_role" "ar_system_database_w" {
  provider = snowflake.useradmin
  count    = var.snowflake_admin_setup ? 1 : 0
  name     = "AR_DB_SYSTEM_W"
}

resource "snowflake_account_role" "data_admin" {
  provider = snowflake.useradmin
  count    = var.snowflake_sso_integration ? 0 : 1
  name     = "DATA_ADMIN"
}

resource "snowflake_account_role" "loader_admin" {
  provider = snowflake.useradmin
  count    = var.snowflake_admin_setup ? 1 : 0
  name     = "LOADER_ADMIN"
}
resource "snowflake_account_role" "tag_admin" {
  provider = snowflake.useradmin
  count    = var.snowflake_admin_setup ? 1 : 0
  name     = "TAG_ADMIN"
}

resource "snowflake_account_role" "transformer_admin" {
  provider = snowflake.useradmin
  count    = var.snowflake_admin_setup ? 1 : 0
  name     = "TRANSFORMER_ADMIN"
}

resource "snowflake_grant_privileges_to_account_role" "assign_tag_grant" {
  provider = snowflake.accountadmin
  count    = var.snowflake_admin_setup ? 1 : 0

  privileges        = ["APPLY TAG"]
  account_role_name = "TAG_ADMIN"
  on_account        = true
  depends_on        = [snowflake_account_role.tag_admin]
}

resource "snowflake_grant_privileges_to_account_role" "execute_task_grant" {
  provider          = snowflake.accountadmin
  count             = var.snowflake_admin_setup ? 1 : 0
  privileges        = ["EXECUTE TASK"]
  account_role_name = "SYSADMIN"
  on_account        = true
}
###############
## WAREHOUSE ##
###############

resource "snowflake_warehouse" "sys_warehouse" {
  provider              = snowflake.sysadmin
  name                  = "SYSTEM_${var.project_name}"
  warehouse_size        = "XSMALL"
  auto_suspend          = 60
  max_cluster_count     = 2
  min_cluster_count     = 1
  max_concurrency_level = 1
  #resource_monitor = "MONITOR_${var.project_name}"# Disabled due to currently recurring account admin for warehouse creation
  scaling_policy            = "ECONOMY"
  initially_suspended       = true
  warehouse_type            = "STANDARD"
  auto_resume               = true
  enable_query_acceleration = false
}


resource "snowflake_tag" "billing_tag" {
  provider = snowflake.sysadmin
  count    = var.snowflake_admin_setup ? 1 : 0

  database = "SYSTEM"
  schema   = "PUBLIC"
  name     = "PROJECT"
  comment  = "Tag used to ascribe ownership of objects and resoures to projects"
  depends_on = [
    snowflake_database.system_database,
    snowflake_warehouse.sys_warehouse
  ]
}


resource "snowflake_tag" "pii_tag" {
  provider = snowflake.sysadmin
  count    = var.snowflake_admin_setup ? 1 : 0

  database = "SYSTEM"
  schema   = "PUBLIC"
  name     = "PII"
  comment  = "Tag used to designate Personal identifieable information"

  depends_on = [
    snowflake_warehouse.sys_warehouse,
    snowflake_database.system_database
  ]
}
