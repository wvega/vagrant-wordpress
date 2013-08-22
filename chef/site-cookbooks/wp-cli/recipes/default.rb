#
# Cookbook Name:: wp-cli
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "git"
include_recipe "subversion"

vagrant_home = File.expand_path('~vagrant')
vagrant_bash_profile = File.join(vagrant_home, '.bash_profile')

bash "install wp-cli" do
  code <<-EOF
  curl http://wp-cli.org/installer.sh | sudo -u vagrant bash

  sed -i "/export PATH/d" #{vagrant_bash_profile}

  echo '# WP-CLI path' >> #{vagrant_bash_profile}
  echo 'PATH=$PATH:#{vagrant_home}/.wp-cli/bin/' >> #{vagrant_bash_profile}
  echo '' >> #{vagrant_bash_profile}
  echo 'export PATH' >> #{vagrant_bash_profile}
  EOF
  not_if {File.exists?(File.join(vagrant_home, '.wp-cli', 'bin', 'wp'))}
end
