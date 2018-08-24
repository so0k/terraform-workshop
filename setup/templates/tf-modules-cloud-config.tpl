#cloud-config
# Order of cloud-init execution - https://stackoverflow.com/a/37190866/138469
hostname: modules
repo_update: true
repo_upgrade: all
packages:
  - zip
  - jq
  # docker requirements
  - apt-transport-https
  - ca-certificates
  - software-properties-common

# one time setup
runcmd:
  - /usr/local/sbin/install_docker.sh
  - /usr/local/sbin/install_sigil.sh
  - /usr/local/sbin/setup.sh
  - docker run -d -p 80:8080 -v /tmp:/tmp --env-file ~ubuntu/modules-env quay.io/honestbee/s3server:latest -bucket=s3://${modules_bucket} -s3region=${aws_region}

output:
  all: '| tee -a /var/log/cloud-init-output.log'

groups:
  - training
# see http://cloudinit.readthedocs.io/en/latest/topics/modules.html#users-and-groups
users:
  - default

write_files:
  - path: /usr/local/sbin/install_sigil.sh    
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${sigil_version}
        ARCH=$(uname -sm|tr \  _)
        curl -L https://github.com/gliderlabs/sigil/releases/download/v$${VERSION}/sigil_$${VERSION}_$${ARCH}.tgz | tar -zxC /usr/local/bin
  - path: /usr/local/sbin/setup.sh    
    permissions: '0755'
    content: |
        #!/bin/bash
        echo "AWS_ACCESS_KEY_ID=${aws_key}" >> ~ubuntu/modules-env
        echo "AWS_SECRET_ACCESS_KEY=${aws_secret}" >> ~ubuntu/modules-env
  - path: /usr/local/sbin/install_docker.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${docker_version}
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable"
        sudo apt-get update
        sudo apt-get install docker-ce=$${VERSION} -y
        sudo usermod -aG docker ubuntu
