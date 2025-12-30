#!/bin/bash
# Mise à jour et installation d'Ansible
apt-get update
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible sshpass

# Génération de la clé SSH pour l'utilisateur vagrant
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 2048 -f /home/vagrant/.ssh/id_rsa -q -N ""
    chown vagrant:vagrant /home/vagrant/.ssh/id_rsa*
fi

# Copie de la clé publique dans le dossier partagé pour que Node01/02 puissent la récupérer
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/keys/id_rsa.pub

# Installation des collections Ansible requises
runuser -l vagrant -c "ansible-galaxy collection install ansible.windows community.windows community.general"