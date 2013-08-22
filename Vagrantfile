  # -*- mode: ruby -*-
# vi: set ft=ruby :

hostname = "local.karrenmgarces.com"
ip = "10.21.8.13"

Vagrant.configure("2") do |config|

  # Synced folders

  config.vm.synced_folder("wordpress", "/var/www/wordpress/")

  # Chef configuration

  # temporary fix for missing symbolink link in fedora-17 box
  config.vm.provision :shell, :inline => "sudo ln -fs /usr/local/bin/chef-solo /usr/bin/"

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["chef/cookbooks", "chef/site-cookbooks"]
    chef.roles_path = ["chef/roles"]

    chef.add_role "wordpress"

    chef.json = {
      :mysql => {
        "server_root_password" => "password",
        "server_repl_password" => "password",
        "server_debian_password" => "password",
        "bind_address" => hostname
      },
      :wordpress => {
        "version" => "latest",
        "db" => {
          "database" => "wordpress",
          "user" => "root",
          "password" => "password"
        }
      },
      :java => {
        "jdk_version" => 7
      }
    }
  end

  # Single VM

  config.vm.box = "fedora-17"
  config.vm.hostname = hostname
  config.vm.network :private_network, ip: ip

  config.vm.provider :virtualbox do |vb|
    vb.name = "WordPress"
  end

  # Multiple VMs (currently not working)

  # config.vm.define :local do |local|
  #   local.vm.box = "fedora-18"
  #   local.vm.hostname = hostname
  #   local.vm.network :private_network, ip: ip

  #   local.vm.provider :virtualbox do |vb|
  #     vb.name = "AWPCP"
  #   end
  # end

  # config.vm.define :remote do |remote|
  #   remote.vm.box = 'dummy'
  #   remote.ssh.username = 'ec2-user'
  #   remote.ssh.private_key_path = "awpcp.pem"

  #   remote.vm.provider :aws do |aws|
  #     aws.access_key_id = "AKIAJRA3WQG34XVTNFXQ"
  #     aws.secret_access_key = "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"
  #     aws.security_groups = ['default']
  #     aws.keypair_name = 'awpcp'

  #     aws.region = "us-east-1"
  #     aws.ami = "ami-4b0b6422"

  #     aws.user_data = <<-EOF
  #     #!/bin/sh
  #     sed -i -e 's/^\(Defaults.*requiretty\)/#\1/' /etc/sudoers
  #     yum install rsync -y
  #     EOF
  #   end
  # end
end
