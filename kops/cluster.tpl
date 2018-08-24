apiVersion: kops/v1alpha2
kind: Cluster
metadata:
  name: $cluster_name
spec:
  api:
    dns: {}
  authorization:
    rbac: {}
  channel: stable
  addons:
  - manifest: s3://$addons_bucket_name/$cluster_name/custom-channel.yaml
  - manifest: kubernetes-dashboard
  - manifest: monitoring-standalone
  cloudProvider: aws
  configBase: s3://$state_bucket_name/$cluster_name
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-ap-southeast-1a
      name: a
    name: main
  - etcdMembers:
    - instanceGroup: master-ap-southeast-1a
      name: a
    name: events
  iam:
    allowContainerRegistry: true
    legacy: false
  additionalPolicies:
    master: |
      [
        {
            "Sid": "kopsK8sS3AddonsGetListBucket",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$addons_bucket_name"
            ]
        },
        {
            "Sid": "kopsK8sS3AddonsMasterBucketFullGet",
            "Effect": "Allow",
            "Action": [
                "s3:Get*"
            ],
            "Resource": "arn:aws:s3:::$addons_bucket_name/$cluster_name/*"
        }
      ]
    node: |
      [
        {
          "Effect": "Allow",
          "Action": [
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:AttachLoadBalancers",
            "autoscaling:DetachLoadBalancers",
            "autoscaling:DetachLoadBalancerTargetGroups",
            "autoscaling:AttachLoadBalancerTargetGroups",
            "autoscaling:DescribeLoadBalancerTargetGroups",
            "cloudformation:*",
            "elasticloadbalancing:*",
            "elasticloadbalancingv2:*",
            "ec2:DescribeInstances",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeRouteTables",
            "ec2:DescribeVpcs",
            "iam:GetServerCertificate",
            "iam:ListServerCertificates"
          ],
          "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CancelUpdateStack",
                "cloudformation:ContinueUpdateRollback",
                "cloudformation:CreateStack",
                "cloudformation:CreateUploadBucket",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeAccountLimits",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeStackResource",
                "cloudformation:DescribeStackResources",
                "cloudformation:DescribeStacks",
                "cloudformation:GetStackPolicy",
                "cloudformation:ListStackResources",
                "cloudformation:ListStacks",
                "cloudformation:SetStackPolicy",
                "cloudformation:UpdateStack",
                "iam:AddUserToGroup",
                "iam:AttachUserPolicy",
                "iam:CreateAccessKey",
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:CreateUser",
                "iam:DeleteAccessKey",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:DeleteRole",
                "iam:DeleteUser",
                "iam:DeleteUserPolicy",
                "iam:DetachUserPolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:GetUser",
                "iam:GetUserPolicy",
                "iam:ListAccessKeys",
                "iam:ListGroups",
                "iam:ListGroupsForUser",
                "iam:ListInstanceProfiles",
                "iam:ListPolicies",
                "iam:ListPolicyVersions",
                "iam:ListRoles",
                "iam:ListUserPolicies",
                "iam:ListUsers",
                "iam:PutUserPolicy",
                "iam:RemoveUserFromGroup",
                "iam:UpdateUser",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeAvailabilityZones"
            ],
            "Resource": [
                "*"
            ]
        }
      ]
  kubernetesApiAccess:
  - 0.0.0.0/0
  kubernetesVersion: 1.9.9
  masterPublicName: api.$cluster_name
  networkCIDR: 172.20.0.0/16
  networking:
    kubenet: {}
  nonMasqueradeCIDR: 100.64.0.0/10
  sshAccess:
  - 0.0.0.0/0
  subnets:
  - cidr: 172.20.32.0/19
    name: ap-southeast-1a
    type: Public
    zone: ap-southeast-1a
  topology:
    dns:
      type: Public
    masters: public
    nodes: public

---

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: $cluster_name
  name: master-ap-southeast-1a
spec:
  image: kope.io/k8s-1.9-debian-stretch-amd64-hvm-ebs-2018-05-27
  machineType: t2.medium
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-ap-southeast-1a
  role: Master
  subnets:
  - ap-southeast-1a

---

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: $cluster_name
  name: nodes
spec:
  image: kope.io/k8s-1.9-debian-stretch-amd64-hvm-ebs-2018-05-27
  machineType: t2.medium
  maxSize: 3
  minSize: 3
  nodeLabels:
    kops.k8s.io/instancegroup: nodes
  role: Node
  subnets:
  - ap-southeast-1a
