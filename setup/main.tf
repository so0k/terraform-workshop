variable aws_access_key {}
variable aws_secret_key {}
variable aws_region {
    default = "ap-southeast-1"
}
variable ingress_cidr_blocks {
    type = "list"
}
variable "subdomain" {
    default = "training"
}
variable "domain" {
    default = "honestbee"
}
variable "tld" {
    default = "com"
}

variable "users" {
    type = "list"
    default = [
        "bee01",
        "bee02",
        "bee03",
        "bee04",
        "bee05",
        "bee06",
        "bee07",
        "bee08",
        "bee09",
        "bee10",
    ]
}

provider "aws" {
    version     = "~> 0.1"

    access_key  = "${var.aws_access_key}"
    secret_key  = "${var.aws_secret_key}"
    region      = "${var.aws_region}"
}

#provider configuration
provider "tls" {
    version     = "~> 0.1"
}

provider "local" {
    version     = "~> 0.1"
}

provider "template" {
    version     = "~> 0.1"
}

provider "null" {
    version     = "~> 0.1"
}

# ubuntu user ssh keys..
resource "tls_private_key" "user-ssh-keys" {
    count     = "${length(var.users)}"
    algorithm = "RSA"
    rsa_bits  = "2048"
}

# private
resource "local_file" "user-ssh-private-keys" {
    count    = "${length(var.users)}"
    content  = "${element(tls_private_key.user-ssh-keys.*.private_key_pem, count.index)}"
    filename = "./generated/${var.users[count.index]}"
}

# public
resource "local_file" "user-ssh-public-keys" {
    count    = "${length(var.users)}"
    content  = "${element(tls_private_key.user-ssh-keys.*.public_key_openssh, count.index)}"
    filename = "./generated/${var.users[count.index]}.pub"
}

resource "aws_key_pair" "user-ssh-keys" {
    count    = "${length(var.users)}"
    key_name   = "${var.users[count.index]}"
    public_key = "${element(tls_private_key.user-ssh-keys.*.public_key_openssh, count.index)}"
}

resource "aws_security_group" "workshop" {
    name        = "allow_all"
    description = "Workshop - Allow all inbound traffic"
    vpc_id      = "vpc-df585ebb"

    ingress {
        protocol  = -1
        self      = true
        from_port = 0
        to_port   = 0
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
    count         = "${length(var.users)}"
    name          = "${var.users[count.index]}"
}

resource "aws_iam_user_policy_attachment" "aws_users" {
    count         = "${length(var.users)}"
    user          = "${element(aws_iam_user.aws_users.*.name,count.index)}"
    policy_arn    = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_access_key" "aws_keys" {
    count         = "${length(var.users)}"
    user          = "${element(aws_iam_user.aws_users.*.name,count.index)}"
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
        tf_version             = "0.10.6"
        sigil_version          = "0.4.0"
        git_repo               = "https://github.com/honestbee/terraform-workshop.git"
        ws_dir                 = "terraform-workshop"
        user                   = "${var.users[count.index]}"
        training_password_hash = "${data.null_data_source.password_hash.outputs["training"]}"
        aws_key                = "${element(aws_iam_access_key.aws_keys.*.id,count.index)}"
        aws_secret             = "${element(aws_iam_access_key.aws_keys.*.secret,count.index)}"
        aws_region             = "ap-southeast-1"
    }
}

resource "aws_instance" "workstations" {
    count                  = "${length(var.users)}"

    vpc_security_group_ids = ["${aws_security_group.workshop.id}"]
    user_data              = "${element(data.template_cloudinit_config.workstations.*.rendered,count.index)}"
    ami                    = "ami-032fb460"
    instance_type          = "t2.micro"

    key_name               = "${var.users[count.index]}"
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

output "instances" {
    value = "${zipmap(var.users,aws_instance.workstations.*.public_ip)}"
}
