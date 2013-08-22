#
# Cookbook Name:: phantomjs
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

remote_file File.join(Chef::Config[:file_cache_path], "phantomjs-1.9.1-linux-i686.tar.bz2") do
  source "https://phantomjs.googlecode.com/files/phantomjs-1.9.1-linux-i686.tar.bz2"
  action :create_if_missing
  mode "0644"
  notifies :run, "bash[install-phandtom-js]", :immediately
end

directory "/usr/local/phantomjs" do
  owner "root"
  recursive true
end

bash "install-phandtom-js" do
  cwd "/usr/local"
  code <<-EOF
  tar -xjvf #{File.join(Chef::Config[:file_cache_path], "phantomjs-1.9.1-linux-i686.tar.bz2")}
  mv phantomjs-1.9.1-linux-i686 phantomjs
  ln -s /usr/local/phantomjs/bin/phantomjs /usr/local/bin
  EOF
  not_if {Dir.exists?("/usr/local/phantomjs")}
  action :nothing
end
