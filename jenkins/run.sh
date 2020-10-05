#!/bin/bash

CODENAME=$(grep -w ^VERSION_CODENAME /etc/os-release |cut -d = -f2)

##Terraform installation
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
echo "deb [arch=amd64] https://apt.releases.hashicorp.com ${CODENAME} main" >> /etc/apt/sources.list
apt-get update && apt-get install -y terraform

##Ansible installation
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" >>/etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
apt update && apt install -y ansible

##helm3 installation
curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 /tmp/get_helm.sh
/tmp/get_helm.sh

##kubectl installation
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

##Jenkins plugins installation
/usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
