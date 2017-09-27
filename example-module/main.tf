provider "null" {
  version = "~> 1.0"
}

resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "echo 'Hello World'"
  }
}

