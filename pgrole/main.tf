data "terraform_remote_state" "rds_instance" {
  backend = "consul"

  config {
    address = "< fill me in >:8500"
    path    = "training/rds"
  }
}

module "postgres-db" {
  source = "git@github.com:honestbee/tf-modules.git?ref=tags/1.0.4//postgres-db"

  provider_db = {
    host     = "< fill me in >"
    name     = "master"
    username = "honestbee"
    password = "< fill me in >"
  }

  db = {
    name     = "bee_db"
    username = "bee"
  }
}
