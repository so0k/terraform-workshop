output "db_password" {
  description = "The master password for the db instance"
  value       = "${module.postgres-instance.db_password}"
  sensitive   = true
}

output "db_host" {
  description = "The endpoint for the db instance"
  value       = "${module.postgres-instance.db_host}"
}
