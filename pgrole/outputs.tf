output "db_info" {
  value = "${module.postgres-db.db_info}"
  sensitive = true
}
