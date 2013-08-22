#
# Cookbook Name:: selenium
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute


include_recipe 'selenium::default'


directory node['selenium']['server']['install_path'] do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end

version = node['selenium']['server']['version']
path = File.join(node['selenium']['server']['install_path'], "selenium-server-standalone-#{version}.jar")

remote_file path do
  source "http://selenium.googlecode.com/files/selenium-server-standalone-#{version}.jar"
  action :create_if_missing
  mode "0644"
end

directory node['selenium']['server']['log_path'] do
  owner 'root'
  recursive true
end

directory "/usr/local/lib/systemd/system" do
  owner "root"
  mode "0755"
  recursive true
  action :create
end

template "/usr/local/lib/systemd/system/selenium-server.service" do
  source "selenium-server.service.erb"
  mode 644
  owner "root"
  group "root"
end

bash "selenium-server-systemd" do
  code <<-EOF
  ln -s /usr/local/lib/systemd/system/selenium-server.service /etc/systemd/system/selenium-server.service
  systemctl enable selenium-server.service
  EOF
  not_if {File.exists?("/etc/systemd/system/selenium-server.service")}
end

bash "start-selenium-server" do
  code "systemctl restart selenium-server.service"
end
