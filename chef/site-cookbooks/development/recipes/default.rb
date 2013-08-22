#
# Cookbook Name:: awpcp-database
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "iptables"

include_recipe "mysql::server"
include_recipe "mysql::ruby"
include_recipe "wordpress"

include_recipe "wp-cli"
include_recipe "phantomjs"
include_recipe "selenium::server"
include_recipe "phpunit"

iptables_rule "all_http"
iptables_rule "all_ssh"
iptables_rule "all_mysql"


# Install autojump
# TODO: create a recipe for autojump
package "autojump" do
  action :install
end


# Configure PHP and install extensions

bash "configure-php" do
  code <<-EOF
  sed -i s/'display_errors = Off'/'display_errors = On'/ /etc/php.ini
  sed -i s/'html_errors = Off'/'html_errors = On'/ /etc/php.ini
  systemctl restart httpd.service
  EOF
end

package "php-gd" do
  action :install
end

# TODO: install and configure XDebug
package "php-pecl-xdebug" do
  action :install
end


# WordPress Directory permissions

directory node['wordpress']['dir'] do
  owner "vagrant"
  group "vagrant"
  mode "0755"
  recursive true
end

# TODO: fix permissions for uploads directory
directory File.join(node['wordpress']['dir'], 'wp-content', 'uploads') do
  owner "vagrant"
  group "vagrant"
  mode "0755"
  recursive true
end

# TODO: fix permissions for upgrade directory
directory File.join(node['wordpress']['dir'], 'wp-content', 'upgrade') do
  owner "vagrant"
  group "vagrant"
  mode "0755"
  recursive true
end

# TODO: apparently the wordpress directory is not owned by vagrant user

template File.join(node['wordpress']['dir'], '.htaccess') do
  source "htaccess.erb"
  mode "0644"
  owner "vagrant"
  group "vagrant"
end


# Install WordPress

if node.has_key?("ec2")
  fqdn = node['ec2']['public_hostname']
else
  fqdn = node['fqdn']
end

bash "wordpress-config" do
  cwd node['wordpress']['dir']
  code <<-EOC
rm wp-config.php
~vagrant/.wp-cli/bin/wp core config --dbname=wordpress --dbuser=root --dbpass=password --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP
  EOC
  action :nothing
  subscribes :run, "template[#{node['wordpress']['dir']}/wp-config.php]", :delayed
  notifies :run, "bash[wordpress-install]", :delayed
end

bash "wordpress-install" do
  cwd node['wordpress']['dir']
  code <<-EOC
  ~vagrant/.wp-cli/bin/wp core install --title="WordPress" --admin_email=wvega@wvega.com --admin_password=password --url=http://#{fqdn}/wp-admin/install.php
  touch .installed
  EOC
  # code <<-EOC
  # curl --data-urlencode weblog_title=AWPCP \
  #      --data-urlencode user_name=admin \
  #      --data-urlencode admin_password=password \
  #      --data-urlencode admin_password2=password \
  #      --data-urlencode admin_email=wvega+admin@gmail.com \
  #      --data-urlencode blog_public=1 \
  #      http://#{fqdn}/wp-admin/install.php?step=2
  # EOC
  action :nothing
  not_if {File.exists?(File.join(node['wordpress']['dir'], '.installed'))}
  notifies :run, "bash[wordpress-users]", :delayed
  notifies :run, "bash[wordpress-tests]", :delayed
end

bash "wordpress-users" do
  cwd node['wordpress']['dir']
  code <<-EOC
if ! (~vagrant/.wp-cli/bin/wp user list --fields=user_email | grep john@wvega.com); then
  ~vagrant/.wp-cli/bin/wp user create john john@wvega.com --user_pass=password --display_name="John Doe"
fi

if ! (~vagrant/.wp-cli/bin/wp user list --fields=user_email | grep jane@wvega.com); then
  ~vagrant/.wp-cli/bin/wp user create jane jane@wvega.com --user_pass=password --display_name="Jane Doe"
fi
  EOC
  action :nothing
end

# Install WordPress Testing Framework
bash "wordpress-tests" do
  cwd node['wordpress']['dir']
  cwd "/var/www/wordpress/"
  code <<-EOF
  ~vagrant/.wp-cli/bin/wp core init-tests /usr/local/wp-tests --dbname=awpcp --dbuser=root --dbpass=password

  sed -i s/'Test Blog'/'AWPCP Test Blog'/ /usr/local/wp-tests/wp-tests-config.php
  sed -i s/admin@example.org/wvega+admin@wvega.com/ /usr/local/wp-tests/wp-tests-config.php
  sed -i s/example.org/#{fqdn}/ /usr/local/wp-tests/wp-tests-config.php
  sed -i s/wptests_/wp_/ /usr/local/wp-tests/wp-tests-config.php
  EOF
  not_if {File.exists?('/usr/local/wp-tests')}
  action :nothing
end
