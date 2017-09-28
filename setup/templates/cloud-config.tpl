#cloud-config
# Order of cloud-init execution - https://stackoverflow.com/a/37190866/138469
hostname: ${user}
repo_update: true
repo_upgrade: all
packages:
  - zip
  - jq
  - graphviz # allow ppl to run dot

# one time setup
runcmd:
  - /usr/local/sbin/install_terraform.sh
  - /usr/local/sbin/install_sigil.sh
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
        mv terraform /usr/bin/
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
        sigil -p -f main.tf.tpl aws_key=${aws_key} aws_secret=${aws_secret} aws_region=${aws_region} > main.tf
        sigil -p -f terraform.tfvars.tpl aws_key=${aws_key} aws_secret=${aws_secret} > terraform.tfvars
        rm *.tpl
        cd ..
        chown -R training:training ${ws_dir}/
