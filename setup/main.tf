variable aws_access_key {}
variable aws_secret_key {}

variable aws_region {
  default = "ap-southeast-1"
}

variable ingress_cidr_blocks {
  type = "list"
}

variable instance_type_ws {
  default = "t2.micro"
}

variable "subdomain" {
  default = "training"
}

variable "domain" {
  default = "swatrider"
}

variable "tld" {
  default = "com"
}

variable "users" {
  type = "list"

  default = [
    "rider01",
  ]

  # "rider02",
  # "rider03",
  # "rider04",
  # "rider02",
  # "rider03",
  # "rider04",
  # "rider05",
  # "rider06",
  # "rider07",
  # "rider08",
  # "rider09",
  # "rider10",
}

provider "aws" {
  version = "~> 0.1"

  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

#provider configuration
provider "tls" {
  version = "~> 0.1"
}

provider "local" {
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

provider "null" {
  version = "~> 0.1"
}

# ubuntu user ssh keys..
resource "tls_private_key" "user-ssh-keys" {
  count     = "${length(var.users)}"
  algorithm = "RSA"
  rsa_bits  = "2048"
}

# honestbee/tf-modules deploy key
resource "tls_private_key" "deploy-key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

# private
resource "local_file" "user-ssh-private-keys" {
  count    = "${length(var.users)}"
  content  = "${element(tls_private_key.user-ssh-keys.*.private_key_pem, count.index)}"
  filename = "./generated/${var.users[count.index]}"

  provisioner "local-exec" {
    command = "chmod 600 ./generated/${var.users[count.index]}"
  }
}

# public
resource "local_file" "user-ssh-public-keys" {
  count    = "${length(var.users)}"
  content  = "${element(tls_private_key.user-ssh-keys.*.public_key_openssh, count.index)}"
  filename = "./generated/${var.users[count.index]}.pub"
}

resource "aws_key_pair" "user-ssh-keys" {
  count      = "${length(var.users)}"
  key_name   = "${var.users[count.index]}"
  public_key = "${element(tls_private_key.user-ssh-keys.*.public_key_openssh, count.index)}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default_a" {
  availability_zone = "${var.aws_region}a"
}

data "aws_subnet" "default_b" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_security_group" "workshop" {
  name        = "allow_all"
  description = "Workshop - Allow all inbound traffic"
  vpc_id      = "${data.aws_vpc.default.id}"

  ingress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_user" "aws_users" {
  count = "${length(var.users)}"
  name  = "${var.users[count.index]}"

  force_destroy = true
}

resource "aws_iam_user_policy_attachment" "aws_users" {
  count      = "${length(var.users)}"
  user       = "${element(aws_iam_user.aws_users.*.name,count.index)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_user_policy_attachment" "aws_users_rds" {
  count      = "${length(var.users)}"
  user       = "${element(aws_iam_user.aws_users.*.name,count.index)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_user_policy_attachment" "aws_users_r53" {
  count      = "${length(var.users)}"
  user       = "${element(aws_iam_user.aws_users.*.name,count.index)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_access_key" "aws_keys" {
  count = "${length(var.users)}"
  user  = "${element(aws_iam_user.aws_users.*.name,count.index)}"
}

data "template_cloudinit_config" "workstations" {
  count         = "${length(var.users)}"
  gzip          = false
  base64_encode = false

  # human readable cloud-config
  part {
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.cloudconfig.*.rendered,count.index)}"
  }
}

# locals would regenerate the hash each time?
# null_data_source is stored in state
data "null_data_source" "password_hash" {
  inputs = {
    training = "${bcrypt("training")}" #this doesn't work and is hardcoded to "training" in cloud-config atm
  }
}

data "template_file" "cloudconfig" {
  count    = "${length(var.users)}"
  template = "${file("./templates/cloud-config.tpl")}"

  vars {
    tf_version             = "0.11.7"
    sigil_version          = "0.4.0"
    kubectl_version        = "v1.9.3"
    helm_version           = "v2.8.2"
    docker_version         = "17.09.0~ce-0~ubuntu"
    usql_version           = "0.5.0"
    consul_version         = "1.0.0"
    kops_version           = "1.9.0"
    git_repo               = "https://github.com/so0k/terraform-workshop.git"
    ws_dir                 = "terraform-workshop"
    user                   = "${var.users[count.index]}"
    training_password_hash = "${data.null_data_source.password_hash.outputs["training"]}"
    aws_key                = "${element(aws_iam_access_key.aws_keys.*.id,count.index)}"
    aws_secret             = "${element(aws_iam_access_key.aws_keys.*.secret,count.index)}"
    aws_region             = "${var.aws_region}"
    sg_group               = "${aws_security_group.workshop.id}"
    vpc                    = "${data.aws_vpc.default.id}"
    subnet_a               = "${data.aws_subnet.default_a.id}"
    subnet_b               = "${data.aws_subnet.default_b.id}"
    ami                    = "${data.aws_ami.ubuntu.id}"
    state_bucket_name      = "${element(aws_s3_bucket.state_store.*.id,count.index)}"
    cluster_name           = "${var.users[count.index]}-cluster.${var.subdomain}.${var.domain}.${var.tld}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "workstations" {
  count = "${length(var.users)}"

  vpc_security_group_ids = ["${aws_security_group.workshop.id}"]
  user_data              = "${element(data.template_cloudinit_config.workstations.*.rendered,count.index)}"
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "${var.instance_type_ws}"

  key_name = "${var.users[count.index]}"

  tags {
    Name = "${var.users[count.index]}"
  }

  lifecycle {
    ignore_changes = ["user_data", "ami"]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${element(tls_private_key.user-ssh-keys.*.private_key_pem, count.index)}"
  }

  provisioner "file" {
    content     = "${tls_private_key.deploy-key.private_key_pem}"
    destination = "/home/ubuntu/.ssh/deploy_key"
  }

  provisioner "file" {
    content     = "${element(tls_private_key.user-ssh-keys.*.private_key_pem, count.index)}"
    destination = "/home/ubuntu/.ssh/kops_key"
  }

  provisioner "file" {
    content     = "${element(tls_private_key.user-ssh-keys.*.public_key_openssh, count.index)}"
    destination = "/home/ubuntu/.ssh/kops_key.pub"
  }

  provisioner "file" {
    content = <<EOF
Host github.com
  IdentityFile ~/.ssh/deploy_key
Host bitbucket.org
  IdentityFile ~/.ssh/deploy_key
EOF

    destination = "/home/ubuntu/.ssh/config"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir ~training/.ssh",
      "sudo mv ~ubuntu/.ssh/config ~training/.ssh/config",
      "sudo mv ~ubuntu/.ssh/deploy_key ~training/.ssh/",
      "sudo mv ~ubuntu/.ssh/kops_key ~training/.ssh/",
      "sudo mv ~ubuntu/.ssh/kops_key.pub ~training/.ssh/",
      "sudo chown -R training:training ~training/.ssh",
      "sudo chmod 600 ~training/.ssh/deploy_key",
      "sudo chmod 600 ~training/.ssh/kops_key",
    ]
  }
}

resource "cloudflare_record" "training_ns" {
  count  = "${length(aws_route53_zone.training.name_servers)}"
  domain = "${var.domain}.${var.tld}"
  name   = "${var.subdomain}"
  type   = "NS"
  value  = "${element(aws_route53_zone.training.name_servers,count.index)}"
}

resource "aws_route53_zone" "training" {
  name = "${var.subdomain}.${var.domain}.${var.tld}"

  tags {
    Environment = "Training"
  }
}

# create a DNS record per user
resource "aws_route53_record" "hosts" {
  count   = "${length(var.users)}"
  zone_id = "${aws_route53_zone.training.zone_id}"
  name    = "${element(var.users,count.index)}.${var.subdomain}.${var.domain}.${var.tld}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.workstations.*.public_ip,count.index)}"]
}

output "subdomain_nameservers" {
  value = [
    "${aws_route53_zone.training.name_servers.0}",
    "${aws_route53_zone.training.name_servers.1}",
    "${aws_route53_zone.training.name_servers.2}",
    "${aws_route53_zone.training.name_servers.3}",
  ]
}

output "deploy_key" {
  value = "${tls_private_key.deploy-key.public_key_openssh}"
}

output "instances" {
  value = "${zipmap(var.users,aws_instance.workstations.*.public_ip)}"
}
