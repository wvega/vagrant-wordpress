# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

VM_HOSTNAME = "example.local"
VM_ADDRESS = "10.10.10.2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provision "shell", path: "scripts/vagrant-bootstrap.sh"

  config.vm.define :local do |local|
    local.vm.box = "fedora-19"
    local.vm.hostname = VM_HOSTNAME
    local.vm.network :private_network, ip: VM_ADDRESS

    local.vm.provider :virtualbox do |vb|
      vb.name = "example"
    end
  end

end
