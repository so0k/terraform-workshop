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
