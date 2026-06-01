output "s3_storage_integration_name" {
  description = "Name of the Snowflake S3 storage integration created by the base module."
  value       = var.snowflake_aws_s3_integration ? snowflake_storage_integration.s3_integration[0].name : null
}

output "s3_storage_aws_role_arn" {
  description = "AWS IAM role ARN configured on the Snowflake S3 storage integration."
  value       = var.snowflake_aws_s3_integration ? snowflake_storage_integration.s3_integration[0].storage_aws_role_arn : null
}

output "s3_storage_aws_iam_user_arn" {
  description = "Snowflake-generated AWS IAM user ARN for the S3 storage integration trust policy."
  value       = var.snowflake_aws_s3_integration ? snowflake_storage_integration.s3_integration[0].storage_aws_iam_user_arn : null
}

output "s3_storage_aws_external_id" {
  description = "Snowflake-generated external ID for the S3 storage integration trust policy."
  value       = var.snowflake_aws_s3_integration ? snowflake_storage_integration.s3_integration[0].storage_aws_external_id : null
  sensitive   = true
}
