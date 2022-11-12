#!/bin/bash
#
echo "=== Setup auth ==="

chown -R ubuntu: /home/ubuntu/.ssh

echo "=== Cloning OpenStack-Helm ==="
git clone https://opendev.org/openstack/openstack-helm-infra.git /opt/openstack-helm-infra
git clone https://opendev.org/openstack/openstack-helm.git /opt/openstack-helm

echo "=== Configuring Inventory ==="

cat > /opt/openstack-helm-infra/tools/gate/devel/multinode-inventory.yaml <<EOF
all:
  children:
    primary:
      hosts:
        node_one:
          ansible_port: 22
          ansible_host: 172.24.1.10
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /etc/openstack-helm/deploy-key.pem
          ansible_ssh_extra_args: -o "LogLevel=FATAL" -o "Compression=yes" -o "DSAAuthentication=yes" -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"
    nodes:
      hosts:
        node_two:
          ansible_port: 22
          ansible_host: 172.24.1.11
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /etc/openstack-helm/deploy-key.pem
          ansible_ssh_extra_args: -o "LogLevel=FATAL" -o "Compression=yes" -o "DSAAuthentication=yes" -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"
        node_three:
          ansible_port: 22
          ansible_host: 172.24.1.12
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /etc/openstack-helm/deploy-key.pem
          ansible_ssh_extra_args: -o "LogLevel=FATAL" -o "Compression=yes" -o "DSAAuthentication=yes" -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"
        node_four:
          ansible_port: 22
          ansible_host: 172.24.1.13
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /etc/openstack-helm/deploy-key.pem
          ansible_ssh_extra_args: -o "LogLevel=FATAL" -o "Compression=yes" -o "DSAAuthentication=yes" -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"
        node_five:
          ansible_port: 22
          ansible_host: 172.24.1.14
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /etc/openstack-helm/deploy-key.pem
          ansible_ssh_extra_args: -o "LogLevel=FATAL" -o "Compression=yes" -o "DSAAuthentication=yes" -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"
        node_six:
          ansible_port: 22
          ansible_host: 172.24.1.15
          ansible_user: ubuntu
          ansible_ssh_private_key_file: /etc/openstack-helm/deploy-key.pem
          ansible_ssh_extra_args: -o "LogLevel=FATAL" -o "Compression=yes" -o "DSAAuthentication=yes" -o "IdentitiesOnly=yes" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"
EOF

tee /opt/openstack-helm-infra/tools/gate/devel/multinode-vars.yaml << EOF
kubernetes_network_default_device: enp1s0
EOF

sudo chown -R ubuntu: /opt

sudo apt-get update -y

sed -i 's/deploy-k8s/deploy-k8s-kubeadm/' /opt/openstack-helm-infra/tools/gate/devel/start.sh
