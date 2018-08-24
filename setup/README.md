# Workshop Setup

This terraform plan will provision workstations for workshop attendees.

To create the workstations, first provide `terraform.tfvars`

```hcl
aws_access_key  = "..."
aws_secret_key  = "..."
ingress_cidr_blocks = [
    "103.13.111.41/32", # Training room public ip
]
```

Also, once applied - add the `deploy_key` to private repositories

```bash
terraform output deploy_key | pbcopy
```

This terraform config will create a new DNS Zone.

To delegate DNS lookup from your main zone, create an NS record with the output
from:

```bash
terraform output subdomain_nameservers
```

To monitor workstation provisioning:

```bash
ssh-keygen -R <dns>
ssh -i generated/<priv-key> ubuntu@<dns>
tail -f /var/log/cloud-init-output.log
```

# TODO:

- Use `https://github.com/Oxalide/terraform-fargate-example` for tf-modules instead of the ec2-instance with docker...

