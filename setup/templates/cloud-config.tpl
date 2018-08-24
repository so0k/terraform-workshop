#cloud-config
# Order of cloud-init execution - https://stackoverflow.com/a/37190866/138469
hostname: ${user}
repo_update: true
repo_upgrade: all
packages:
  - tree
  - zip
  - jq
  - graphviz # allow ppl to run dot
  # docker requirements
  - apt-transport-https
  - ca-certificates
  - software-properties-common

# one time setup
runcmd:
  - /usr/local/sbin/install_terraform.sh
  - /usr/local/sbin/install_kubectl.sh
  - /usr/local/sbin/install_helm.sh
  - /usr/local/sbin/install_docker.sh
  - /usr/local/sbin/install_consul.sh
  - /usr/local/sbin/install_kops.sh
  - /usr/local/sbin/install_channels.sh
  - /usr/local/sbin/install_sigil.sh
  - /usr/local/sbin/install_usql.sh
  - /usr/local/sbin/setup_ws.sh
  - sed -ie "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  - service ssh restart

output:
  all: '| tee -a /var/log/cloud-init-output.log'

groups:
  - training
# see http://cloudinit.readthedocs.io/en/latest/topics/modules.html#users-and-groups
users:
  - default
  - name: training
    primary-group: training
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false
    passwd: "$6$YgikR5Kw$jM0fdsIsxqbR0FA.esbX7mQyzRhn25ovC4lJkmTNBh/KgUI3lBOmo0hCPLrgkiyMRDI/XHl7WtzbMxrxm2eKD0" #${training_password_hash}

write_files:
  - path: /usr/local/sbin/install_terraform.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${tf_version}
        curl -Lo ~/terraform.zip https://releases.hashicorp.com/terraform/$${VERSION}/terraform_$${VERSION}_linux_386.zip
        cd ~
        unzip terraform.zip && rm terraform.zip
        mv terraform /usr/local/bin/
  - path: /usr/local/sbin/install_sigil.sh    
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${sigil_version}
        ARCH=$(uname -sm|tr \  _)
        curl -L https://github.com/gliderlabs/sigil/releases/download/v$${VERSION}/sigil_$${VERSION}_$${ARCH}.tgz | tar -zxC /usr/local/bin
  - path: /usr/local/sbin/setup_ws.sh    
    permissions: '0755'
    content: |
        #!/bin/bash
        cd ~training
        git clone ${git_repo} ${ws_dir}
        cd ${ws_dir}
        # use co-working branch
        git checkout coworking
        # remove workshop setup sub-folder
        rm -rf setup/
        mkdir -p ~training/.aws
        # render templates
        sigil -p -f aws-creds.tpl aws_key=${aws_key} aws_secret=${aws_secret} > ~training/.aws/credentials
        chown -R training:training ~training/.aws/
        sigil -p -f main.tf.tpl aws_key=${aws_key} aws_secret=${aws_secret} aws_region=${aws_region} sg_group=${sg_group} ami=${ami} vpc=${vpc} subnet_a=${subnet_a} > main.tf
        sigil -p -f terraform.tfvars.tpl aws_key=${aws_key} aws_secret=${aws_secret} > terraform.tfvars
        sigil -p -f rds/main.tf.tpl aws_key=${aws_key} aws_secret=${aws_secret} aws_region=${aws_region} sg_group=${sg_group} subnet_a=${subnet_a} subnet_b=${subnet_b}> rds/main.tf
        sigil -p -f rds/terraform.tfvars.tpl aws_key=${aws_key} aws_secret=${aws_secret} aws_region=${aws_region} sg_group=${sg_group} subnet_a=${subnet_a} subnet_b=${subnet_b}> rds/terraform.tfvars
        # sigil -p -f dns/terraform.tfvars.tpl aws_key=${aws_key} aws_secret=${aws_secret} > dns/terraform.tfvars
        sigil -p -f kops/env.tpl aws_key=${aws_key} aws_secret=${aws_secret} state_bucket_name=${state_bucket_name} cluster_name=${cluster_name} > kops/.env
        mkdir -p kops/manifests
        sigil -p -f kops/cluster.yaml.tpl cluster_name=${cluster_name} addons_bucket_name=${addons_bucket_name} > kops/manifests/${cluster_name}.yaml
        sigil -p -f kops/main.tf.tpl dns_zone=${dns_zone} aws_region=${aws_region} cluster_name=${cluster_name} addons_bucket_name=${addons_bucket_name} > kops/main.tf
        rm *.tpl
        rm rds/*.tpl
        # rm dns/*.tpl
        rm kops/*.tpl
        cd ..
        chown -R training:training ${ws_dir}/
        # re-use for Kubernetes / Helm training
        git clone https://github.com/so0k/flask_app_k8s.git
        chown -R training:training flask_app_k8s/
  - path: /usr/local/sbin/install_kubectl.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${kubectl_version}
        curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$${VERSION}/bin/linux/amd64/kubectl
        chmod +x /usr/local/bin/kubectl
  - path: /usr/local/sbin/install_helm.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${helm_version}
        curl -Lo ~/helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-$${VERSION}-linux-amd64.tar.gz
        cd ~
        tar -xzf helm.tar.gz && rm helm.tar.gz
        mv linux-amd64/helm /usr/local/bin/ && rm -rf linux-amd64
  - path: /usr/local/sbin/install_usql.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${usql_version}
        curl -Lo ~/usql.tar.bz2 https://github.com/xo/usql/releases/download/v$${VERSION}/usql-$${VERSION}-linux-amd64.tar.bz2
        cd ~
        tar -xjf usql.tar.bz2 && rm usql.tar.bz2
        mv usql /usr/local/bin/
  - path: /usr/local/sbin/install_consul.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${consul_version}
        curl -Lo ~/consul.zip https://releases.hashicorp.com/consul/$${VERSION}/consul_$${VERSION}_linux_amd64.zip
        cd ~
        unzip consul.zip && rm consul.zip
        mv consul /usr/local/bin/
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
        sudo usermod -aG docker training
  - path: /usr/local/sbin/install_channels.sh
    permissions: '0755'
    content: |
        curl -Lo channels.zip http://tech.honestbee.com/kops-infra/channels-1.7.1-linux-amd64.zip
        unzip channels.zip && rm channels.zip
        mv channels usr/local/bin/
  - path: /usr/local/sbin/install_kops.sh
    permissions: '0755'
    content: |
        #!/bin/bash
        VERSION=${kops_version}
        # VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -LO https://github.com/kubernetes/kops/releases/download/$${VERSION}/kops-linux-amd64
        chmod +x kops-linux-amd64
        sudo mv kops-linux-amd64 /usr/local/bin/kops
