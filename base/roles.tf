


#########################
## Project based Roles ##
#########################

resource "snowflake_account_role" "extra_roles" {
  provider = snowflake.securityadmin
  for_each = toset(var.snowflake_additional_roles)
  name     = each.key
}

#############################
## AR roles for databases ##
#############################


locals {
  all_delivery_databases = concat(var.snowflake_delivery_databases)
  all_source_databases   = concat(var.snowflake_prod_source_databases, var.snowflake_dev_source_databases)

}

## Delivery bases access roles
resource "snowflake_account_role" "ar_db_dds_read" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_delivery_databases : db.name => db }
  name     = "AR_DB_CURATED_${each.key}_R"
}

resource "snowflake_account_role" "ar_db_dds_write" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_delivery_databases : db.name => db }
  name     = "AR_DB_CURATED_${each.key}_W"
}

resource "snowflake_account_role" "dev_ar_db_dds_read" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_delivery_databases : db.name => db }
  name     = "DEV_AR_DB_CURATED_${each.key}_R"
}

resource "snowflake_account_role" "dev_ar_db_dds_write" {
  provider = snowflake.securityadmin

  for_each = { for db in local.all_delivery_databases : db.name => db }
  name     = "DEV_AR_DB_CURATED_${each.key}_W"
}

## Source databases
resource "snowflake_account_role" "ar_db_source_read" {
  provider = snowflake.securityadmin

  for_each = { for db in local.all_source_databases : db.name => db }
  name     = "AR_DB_SOURCE_${each.key}_R"
}

resource "snowflake_account_role" "ar_db_source_write" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_source_databases : db.name => db }
  name     = "AR_DB_SOURCE_${each.key}_W"
}

resource "snowflake_account_role" "dev_ar_db_source_read" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_source_databases : db.name => db }
  name     = "DEV_AR_DB_SOURCE_${each.key}_R"
}

resource "snowflake_account_role" "dev_ar_db_source_write" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_source_databases : db.name => db }
  name     = "DEV_AR_DB_SOURCE_${each.key}_W"
}

resource "snowflake_account_role" "ar_schema_read" {
  provider = snowflake.securityadmin
  for_each = { for role in var.snowflake_schema_role_read : role.name => role }
  name     = "AR_SCHEMA_${each.value.name}_R"
}


resource "snowflake_account_role" "ar_db_outgoing_share_r" {
  provider = snowflake.securityadmin
  for_each = { for share in var.snowflake_outgoing_share : share.name => share }
  name     = "AR_DB_OUTGOING_SHARE_${each.value.name}_R"
}



resource "snowflake_account_role" "ar_db_outgoing_share_w" {
  provider = snowflake.securityadmin
  for_each = { for share in var.snowflake_outgoing_share : share.name => share }
  name     = "AR_DB_OUTGOING_SHARE_${each.value.name}_W"
}
#############################
## System Functional Roles ##
#############################

resource "snowflake_account_role" "loader_role" {
  provider = snowflake.securityadmin
  for_each = { for db in local.all_source_databases : db.name => db }
  name     = "LOADER_${each.value.name}"
  comment  = "role for dataloaders"
}
