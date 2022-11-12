#!/bin/bash
#
HOME=/mnt/extra/

cat > /mnt/extra/management.xml <<EOF
<network>
  <name>management</name>
  <forward mode='nat'/>
  <bridge name='virbr100' stp='off' macTableManager="kernel"/>
  <mtu size="9216"/>
  <mac address='52:54:00:8a:8b:cd'/>
  <ip address='172.24.1.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='172.24.1.2' end='172.24.1.199'/>
      <host mac='52:54:00:8a:8b:c1' name='n1' ip='172.24.1.10'/>
      <host mac='52:54:00:8a:8b:c2' name='n2' ip='172.24.1.11'/>
      <host mac='52:54:00:8a:8b:c3' name='n3' ip='172.24.1.12'/>
      <host mac='52:54:00:8a:8b:c4' name='n4' ip='172.24.1.13'/>
      <host mac='52:54:00:8a:8b:c5' name='n5' ip='172.24.1.14'/>
      <host mac='52:54:00:8a:8b:c6' name='n6' ip='172.24.1.15'/>
      <host mac='52:54:00:8a:8b:c7' name='n7' ip='172.24.1.16'/>
      <host mac='52:54:00:8a:8b:c8' name='n8' ip='172.24.1.17'/>
      <host mac='52:54:00:8a:8b:c9' name='n8' ip='172.24.1.18'/>
    </dhcp>
  </ip>
</network>
EOF

cat > /mnt/extra/cluster.xml <<EOF
<network>
  <name>cluster</name>
  <bridge name="virbr101" stp='off' macTableManager="kernel"/>
  <mtu size="9216"/> 
</network>
EOF

cat > /mnt/extra/service.xml <<EOF
<network>
  <name>service</name>
  <bridge name="virbr102" stp='off' macTableManager="kernel"/>
  <mtu size="9216"/> 
</network>
EOF

virsh net-define /mnt/extra/management.xml && virsh net-autostart management && virsh net-start management
virsh net-define /mnt/extra/cluster.xml && virsh net-autostart cluster && virsh net-start cluster
virsh net-define /mnt/extra/service.xml && virsh net-autostart service && virsh net-start service

ip a && sudo virsh net-list --all

echo 'kyax7344' > upass
chmod 0400 upass

echo 'gprm8350' > rpass
chmod 0400 rpass

sleep 20

# Node 1
./kvm-install-vm create -c 6 -m 32768 -d 120 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr100 -T US/Eastern -M 52:54:00:8a:8b:c1 n1

# Node 2
./kvm-install-vm create -c 6 -m 32768 -d 120 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr100 -T US/Eastern -M 52:54:00:8a:8b:c2 n2

# Node 3
./kvm-install-vm create -c 6 -m 32768 -d 120 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr100 -T US/Eastern -M 52:54:00:8a:8b:c3 n3

# Node 4
./kvm-install-vm create -c 6 -m 32768 -d 120 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr100 -T US/Eastern -M 52:54:00:8a:8b:c4 n4

# Node 5
./kvm-install-vm create -c 6 -m 32768 -d 120 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr100 -T US/Eastern -M 52:54:00:8a:8b:c5 n5

# Node 6
./kvm-install-vm create -c 6 -m 32768 -d 120 -t ubuntu2004 -f host-passthrough -k /root/.ssh/id_rsa.pub -l /mnt/extra/virt/images -L /mnt/extra/virt/vms -b virbr100 -T US/Eastern -M 52:54:00:8a:8b:c6 n6

sleep 60

virsh list --all && brctl show && virsh net-list --all

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i 'echo "root:gprm8350" | sudo chpasswd'; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i 'echo "ubuntu:kyax7344" | sudo chpasswd'; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo systemctl restart sshd"; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo rm -rf /root/.ssh/authorized_keys"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo hostnamectl set-hostname n$i --static"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo apt update -y && sudo apt-get install -y git vim net-tools wget curl bash-completion apt-utils iperf iperf3 make mtr traceroute netcat sshpass socat xfsprogs locate jq"; done

#for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo apt-get install ntp ntpdate -y && sudo timedatectl set-ntp on"; done

#for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo modprobe -v xfs && sudo grep xfs /proc/filesystems && sudo modinfo xfs"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo mkdir -p /etc/apt/sources.list.d"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo chmod -x /etc/update-motd.d/*"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i 'cat << EOF | sudo tee /etc/update-motd.d/01-custom
#!/bin/sh
echo "****************************WARNING****************************************
UNAUTHORISED ACCESS IS PROHIBITED. VIOLATORS WILL BE PROSECUTED.
*********************************************************************************"
EOF'; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo chmod +x /etc/update-motd.d/01-custom"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "cat << EOF | sudo tee /etc/modprobe.d/qemu-system-x86.conf
options kvm_intel nested=1
EOF"; done

#for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo DEBIAN_FRONTEND=noninteractive apt-get install linux-generic-hwe-20.04 --install-recommends -y"; done
#for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo apt autoremove -y && sudo apt --fix-broken install -y"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo mkdir -p /etc/systemd/system/networking.service.d"; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "cat << EOF | sudo tee /etc/systemd/system/networking.service.d/reduce-timeout.conf
[Service]
TimeoutStartSec=15
EOF"; done

for i in {1..6}; do qemu-img create -f qcow2 vbdnode1$i 120G; done
for i in {1..6}; do qemu-img create -f qcow2 vbdnode2$i 120G; done
#for i in {1..6}; do qemu-img create -f qcow2 vbdnode3$i 120G; done

for i in {1..6}; do ./kvm-install-vm attach-disk -d 120 -s /mnt/extra/kvm-install-vm/vbdnode1$i.qcow2 -t vdb n$i; done
for i in {1..6}; do ./kvm-install-vm attach-disk -d 120 -s /mnt/extra/kvm-install-vm/vbdnode2$i.qcow2 -t vdc n$i; done
#for i in {1..6}; do ./kvm-install-vm attach-disk -d 120 -s /mnt/extra/kvm-install-vm/vbdnode3$i.qcow2 -t vdd n$i; done

#for i in {1..6}; do virsh attach-interface --domain n$i --type network --source cluster --model e1000 --mac 02:00:aa:0a:01:1$i --config --live; done
#for i in {1..6}; do virsh attach-interface --domain n$i --type network --source service --model e1000 --mac 02:00:aa:0a:02:1$i --config --live; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "cat << EOF | sudo tee /etc/hosts
127.0.0.1 localhost
172.24.1.10  n1
172.24.1.11  n2
172.24.1.12  n3
172.24.1.13  n4
172.24.1.14  n5
172.24.1.15  n6
172.24.1.16  n7
172.24.1.17  n8
172.24.1.18  n9
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "cat << EOF | sudo tee /etc/sysctl.d/60-lxd-production.conf
fs.inotify.max_queued_events=1048576
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
vm.max_map_count=262144
kernel.dmesg_restrict=1
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh3=8192
net.core.bpf_jit_limit=3000000000
kernel.keys.maxkeys=2000
kernel.keys.maxbytes=2000000
net.ipv4.ip_forward=1
EOF"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo sysctl --system"; done

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "#echo vm.swappiness=1 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"; done

for i in {1..6}; do virsh shutdown n$i; done && sleep 10 && virsh list --all && for i in {1..6}; do virsh start n$i; done && sleep 10 && virsh list --all

sleep 30

# Create ssh key at n1 and distribute it 
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "echo 'kyax7344' > upass && chmod 0400 upass"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "echo 'gprm8350' > rpass && chmod 0400 rpass"

ssh -o "StrictHostKeyChecking=no" ubuntu@n1 'ssh-keygen -t rsa -q -N ""'

ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "sshpass -f upass scp '-o StrictHostKeyChecking=no' ~/.ssh/id_rsa* ubuntu@n2:~/.ssh/id_rsa*"

ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "sshpass -f upass ssh-copy-id -o 'StrictHostKeyChecking=no' -i ~/.ssh/id_rsa.pub ubuntu@n2"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "sshpass -f upass ssh-copy-id -o 'StrictHostKeyChecking=no' -i ~/.ssh/id_rsa.pub ubuntu@n3"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "sshpass -f upass ssh-copy-id -o 'StrictHostKeyChecking=no' -i ~/.ssh/id_rsa.pub ubuntu@n4"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "sshpass -f upass ssh-copy-id -o 'StrictHostKeyChecking=no' -i ~/.ssh/id_rsa.pub ubuntu@n5"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "sshpass -f upass ssh-copy-id -o 'StrictHostKeyChecking=no' -i ~/.ssh/id_rsa.pub ubuntu@n6"

for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo mkdir -p /etc/openstack-helm"; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo cp ~/.ssh/id_rsa /etc/openstack-helm/deploy-key.pem"; done
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "sudo chown ubuntu /etc/openstack-helm/deploy-key.pem"; done

# Clone osh-multinode-kvm repository and perform initial provisioning
for i in {1..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "git clone https://github.com/vpasias/osh-multinode-kvm.git"; done

for i in {1..6}; do sshpass -f /mnt/extra/kvm-install-vm/rpass ssh -o StrictHostKeyChecking=no root@n$i "cd /home/ubuntu/osh-multinode-kvm && chmod +x provision.sh && ./provision.sh"; done

# Deploy K8s on n1
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "cd /opt/openstack-helm-infra && make dev-deploy setup-host multinode"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "cp -r /home/ubuntu/osh-multinode-kvm/deploy-k8s-kubeadm.sh /opt/openstack-helm-infra/tools/gate/deploy-k8s-kubeadm.sh"
ssh -o "StrictHostKeyChecking=no" ubuntu@n1 "cd /opt/openstack-helm-infra && make dev-deploy k8s multinode"

# Deploy base infrastracture on nodes n2, n3, n4, n5, n6
for i in {2..6}; do ssh -o "StrictHostKeyChecking=no" ubuntu@n$i "cp /home/ubuntu/osh-multinode-kvm/deploy-base.sh /home/ubuntu/deploy-base.sh && chmod +x /home/ubuntu/deploy-base.sh && cd ~ && ./deploy-base.sh"; done

sudo mkdir ~/.kube
sshpass -f /mnt/extra/kvm-install-vm/rpass scp root@n1:/etc/kubernetes/admin.conf ~/.kube/config
sshpass -f /mnt/extra/kvm-install-vm/rpass scp root@n1:/home/ubuntu/kubeadm.log ~/.kube/kubeadm.log
for i in {2..6}; do scp ~/.kube/kubeadm.log ubuntu@n$i:/home/ubuntu/kubeadm.log; done

discovery_token_ca_cert_hash="$(grep 'discovery-token-ca-cert-hash' ~/.kube/kubeadm.log | head -n1 | awk '{print $2}')"
certificate_key="$(grep 'certificate-key' ~/.kube/kubeadm.log | head -n1 | awk '{print $3}')"

# Deploy k8s infrastracture on nodes n2, n3, n4, n5, n6
sshpass -f /mnt/extra/kvm-install-vm/rpass ssh -o StrictHostKeyChecking=no root@n2 "kubeadm join 172.24.1.10:6443 --token ayngk7.m1555duk5x2i3ctt --discovery-token-ca-cert-hash ${discovery_token_ca_cert_hash} --control-plane --certificate-key ${certificate_key} --apiserver-advertise-address=172.24.1.11"
sshpass -f /mnt/extra/kvm-install-vm/rpass ssh -o StrictHostKeyChecking=no root@n3 "kubeadm join 172.24.1.10:6443 --token ayngk7.m1555duk5x2i3ctt --discovery-token-ca-cert-hash ${discovery_token_ca_cert_hash} --control-plane --certificate-key ${certificate_key} --apiserver-advertise-address=172.24.1.12"

sleep 30

for i in {4..6}; do sshpass -f /mnt/extra/kvm-install-vm/rpass ssh -o StrictHostKeyChecking=no root@n$i "kubeadm join 172.24.1.10:6443 --token ayngk7.m1555duk5x2i3ctt --discovery-token-ca-cert-hash ${discovery_token_ca_cert_hash}"; done

sleep 10

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update -y
sudo apt -y install kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh
helm repo remove stable || true

kubectl version --client
kubeadm version
helm version

#for i in {1..6}; do virsh shutdown n$i; done && sleep 10 && virsh list --all && for i in {1..6}; do virsh start n$i; done && sleep 10 && virsh list --all
