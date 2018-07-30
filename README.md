# Jakarta TF Workshop

Working files for TF Workshop

Request workstation assigned to you and password from trainer

Trainees access:

- [x] ability to launch EC2 instances only if:
  - Owner tag == trainee name
  - region = ap-southeast-1
  - instance type = t2.micro

- [ ] ability to create IAM policy for s3 bucket?
- [ ] ability to create s3 bucket?

Exercises:

1. [x] launch instance
1. [x] launch multiple instances (using count)
1. [ ] modules exercise (which one??) 
  - Could create S3 bucket + bucket policy (using module)
  - Could ask them to use an existing policy and only give them s3 rights...

  problem with s3 exercise is the need for IAM permissions
  problem with RDS exercise is the need to control instance type and cost... it might be better though

1. [x] state manipulation (using consul)

training requirements:
- [ ] tf-modules push to s3 bucket
- [x] tf-modules server over s3
- [x] DNS for tf-modules server
