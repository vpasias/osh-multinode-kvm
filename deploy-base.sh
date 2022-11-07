#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

sudo apt-get update -y
sudo apt-get install --no-install-recommends -y \
        ca-certificates \
        git \
        make \
        nmap \
        curl \
        bc \
        python3-pip \
        dnsutils

: "${HELM_VERSION:="v3.6.3"}"
: "${KUBE_VERSION:="1.21.5-00"}"
: "${YQ_VERSION:="v4.6.0"}"

export DEBCONF_NONINTERACTIVE_SEEN=true
export DEBIAN_FRONTEND=noninteractive

sudo apt purge snapd -y
sudo rm -rf ~/snap /snap /var/snap /var/lib/snapd

sudo swapoff -a

# Enable kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Add some settings to sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

echo "DefaultLimitMEMLOCK=16384" | sudo tee -a /etc/systemd/system.conf
sudo systemctl daemon-reexec

function configure_resolvconf {
  # here with systemd-resolved disabled, we'll have 2 separate resolv.conf
  # 1 - /etc/resolv.conf - to be used for resolution on host

  kube_dns_ip="10.96.0.10"
  # keep all nameservers from both resolv.conf excluding local addresses
  old_ns=$(grep -P --no-filename "^nameserver\s+(?!127\.0\.0\.|${kube_dns_ip})" \
           /etc/resolv.conf /run/systemd/resolve/resolv.conf | sort | uniq)

  # Add kube-dns ip to /etc/resolv.conf for local usage
  sudo bash -c "echo 'nameserver ${kube_dns_ip}' > /etc/resolv.conf"
  if [ -z "${HTTP_PROXY}" ]; then
    sudo bash -c "printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n' > /run/systemd/resolve/resolv.conf"
    sudo bash -c "printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n' >> /etc/resolv.conf"
  else
    sudo bash -c "echo \"${old_ns}\" > /run/systemd/resolve/resolv.conf"
    sudo bash -c "echo \"${old_ns}\" >> /etc/resolv.conf"
  fi

  for file in /etc/resolv.conf /run/systemd/resolve/resolv.conf; do
    sudo bash -c "echo 'search svc.cluster.local cluster.local' >> ${file}"
    sudo bash -c "echo 'options ndots:5 timeout:1 attempts:1' >> ${file}"
  done
}

# NOTE: Clean Up hosts file
sudo sed -i '/^127.0.0.1/c\127.0.0.1 localhost localhost.localdomain localhost4localhost4.localdomain4' /etc/hosts
sudo sed -i '/^::1/c\::1 localhost6 localhost6.localdomain6' /etc/hosts

configure_resolvconf

# shellcheck disable=SC1091
. /etc/os-release

sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

sudo apt remove docker docker.io containerd runc -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update -y

sudo usermod -aG docker ubuntu

# NOTE: Configure docker
docker_resolv="/run/systemd/resolve/resolv.conf"
docker_dns_list="$(awk '/^nameserver/ { printf "%s%s",sep,"\"" $NF "\""; sep=", "} END{print ""}' "${docker_resolv}")"

sudo -E mkdir -p /etc/docker
sudo -E tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "dns": [${docker_dns_list}]
}
EOF

if [ -n "${HTTP_PROXY}" ]; then
  sudo mkdir -p /etc/systemd/system/docker.service.d
  cat <<EOF | sudo -E tee /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=${HTTP_PROXY}"
Environment="HTTPS_PROXY=${HTTPS_PROXY}"
Environment="NO_PROXY=${NO_PROXY}"
EOF
fi

sudo -E apt-get update
sudo -E apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  socat \
  jq \
  util-linux \
  bridge-utils \
  iptables \
  conntrack \
  libffi-dev \
  ipvsadm \
  make \
  bc \
  git-review \
  notary

# Prepare tmpfs for etcd when running on CI
# CI VMs can have slow I/O causing issues for etcd
# Only do this on CI (when user is zuul), so that local development can have a kubernetes
# environment that will persist on reboot since etcd data will stay intact
if [ "$USER" = "zuul" ]; then
  sudo mkdir -p /var/lib/kubeadm/etcd
  sudo mount -t tmpfs -o size=512m tmpfs /var/lib/kubeadm/etcd
fi

# Install YQ
wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz -O - | tar xz && sudo mv yq_linux_amd64 /usr/local/bin/yq

# Install kubeadm kubectl and kublet

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet=$KUBE_VERSION kubeadm=$KUBE_VERSION kubectl=$KUBE_VERSION
sudo apt-mark hold kubelet kubeadm kubectl

# Install Helm
TMP_DIR=$(mktemp -d)
sudo -E bash -c \
  "curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -zxv --strip-components=1 -C ${TMP_DIR}"
sudo -E mv "${TMP_DIR}"/helm /usr/local/bin/helm
rm -rf "${TMP_DIR}"
