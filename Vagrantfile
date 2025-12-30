# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  # Configuration globale VMware
  config.vm.provider "vmware_desktop" do |v|
    v.gui = true
    v.allowlist_verified = true
    v.memory = 2048
    v.cpus = 2
  end

  # --- VM Admin (Ubuntu) ---
  config.vm.define "Admin" do |admin|
    admin.vm.box = "bento/ubuntu-22.04"
    admin.vm.hostname = "admin"
    admin.vm.network "private_network", ip: "192.168.50.10"
    
    # Script pour générer la clé SSH et installer Ansible
    admin.vm.provision "shell", path: "ansible/scripts/setup_admin.sh"
  end

  # --- Node01 (RedHat/AlmaLinux) ---
  config.vm.define "Node01" do |node|
    node.vm.box = "almalinux/9" # Compatible RedHat 9
    node.vm.hostname = "node01"
    node.vm.network "private_network", ip: "192.168.50.20"
    
    # Injection de la clé SSH publique de l'Admin
    node.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      cat /vagrant/keys/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
    SHELL
  end

  # --- Node02 (RedHat/AlmaLinux) ---
  config.vm.define "Node02" do |node|
    node.vm.box = "almalinux/9"
    node.vm.hostname = "node02"
    node.vm.network "private_network", ip: "192.168.50.21"
    
    # Injection de la clé SSH publique de l'Admin
    node.vm.provision "shell", inline: <<-SHELL
      mkdir -p /home/vagrant/.ssh
      cat /vagrant/keys/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
      chown -R vagrant:vagrant /home/vagrant/.ssh
    SHELL
  end

  # --- WinSrv (Windows Server 2019) ---
  config.vm.define "WinSrv" do |win|
    # Note: Cette box doit être compatible vmware. Si elle échoue, essayez "generic/windows2019"
    win.vm.box = "gusztavvargadr/windows-server-2019-standard"
    win.vm.hostname = "winsrv"
    win.vm.network "private_network", ip: "192.168.50.30"
    
    # Configuration WinRM pour Ansible
    win.vm.communicator = "winrm"
    win.winrm.username = "vagrant"
    win.winrm.password = "vagrant"
  end
end