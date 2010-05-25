#   create database $database_name character set utf8;
#   grant all privileges on $database_name.* to '$user'@'localhost' identified by '$password';
#   flush privileges;

require_recipe 'apache'
require_recipe 'php'
require_recipe 'mysql'
require_recipe 'passenger'

gem_package "sinatra"
gem_package "builder"
# Required to run the unit tests
gem_package "rack-test"
# Package libxslt is required by nokogiri
package "libxslt" do
  source "ports"
end
# Use a recent version of mechanize. Should hopefully not conflict with the earlier version currently
# required by the openaustralia parser
gem_package "mechanize" do
  version "0.9.2"
end

# Also need a recent version of nokogiri
gem_package "nokogiri" do
  version "1.3.3"
end

package "php5-simplexml" do
  source "ports"
end

# Bits and pieces needed for the exception mailer for Sinatra
gem_package "rack-rack-contrib" do
  source "http://gems.github.com/"
end

gem_package "tmail"

# Required by the edala scraper (written in php)
package "pear-Net_URL" do
  source "ports"
end

package "php5-tidy" do
  source "ports"
end

# Required by the Kogarah scraper (written in perl)
package "p5-HTML-TableExtract" do
  source "ports"
end

package "p5-HTML-Element-Extended" do
  source "ports"
end

gem_package "rails" do
  version "2.3.5"
end

gem_package "mysql"

# The gems we need for running the rails app are also stored in the app
# For the time being we'll use chef to install the gems rather than running "rake gems:install"
gem_package "haml"
gem_package "geokit"
gem_package "shorturl"
gem_package "nokogiri"
gem_package 'email_spec'

[:production, :test].each do |stage|
  directory node[:planningalerts][stage][:install_path] do
    owner "matthewl"
    group "matthewl"
    mode 0755
    recursive true
  end

  directory "#{node[:planningalerts][stage][:install_path]}/shared/" do
    owner "matthewl"
    group "matthewl"
  end

  directory "#{node[:planningalerts][stage][:install_path]}/shared/pids" do
    owner "matthewl"
    group "matthewl"
  end

  directory "#{node[:planningalerts][stage][:install_path]}/shared/log" do
    mode 0777
  end

  directory "#{node[:planningalerts][stage][:install_path]}/shared/config"

  template "#{@node[:planningalerts][stage][:install_path]}/shared/config/database.yml" do
    source "database.yml.erb"
    variables :stage => stage
  end

  directory "#{@node[:planningalerts][stage][:install_path]}/shared/db/sphinx" do
    recursive true
  end

  template "#{@node[:planningalerts][stage][:install_path]}/shared/config/sphinx.yml" do
    source "sphinx.yml.erb"
    variables :stage => stage
  end

  deploy_revision node[:planningalerts][stage][:install_path] do
    revision stage.to_s
    user "matthewl"
    group "matthewl"
    repo "git://git.openaustralia.org/planningalerts.git"
    # This should not be set to :force_deploy for normal usage
    #action :force_deploy
    scm_provider Chef::Provider::Git
    symlink_before_migrate \
      "config/database.yml" => "planningalerts-app/config/database.yml",
      "config/sphinx.yml" => "planningalerts-app/config/sphinx.yml",
      "config/production.sphinx.conf" => "planningalerts-app/config/production.sphinx.conf"
    #migrate true
    #migration_command "rake db:migrate RAILS_ENV=production"
    purge_before_symlink \
      ["planningalerts-app/log", "planningalerts-app/tmp/pids", "planningalerts-app/public/system"]
    create_dirs_before_symlink \
      ["planningalerts-app/tmp", "planningalerts-app/public", "planningalerts-app/config", "planningalerts-parsers/public"]
    symlinks \
      "system" => "planningalerts-app/public/system",
      "pids" => "planningalerts-app/tmp/pids",
      "log" => "planningalerts-app/log",
      "../current/planningalerts-parsers/public" => "planningalerts-app/public/scrapers"
    # We'll wait until the configuration gets overridden below before we restart passenger. So, below is commented out
    #restart_command "touch planningalerts-app/tmp/restart.txt"  
    enable_submodules true
  end
  
  ruby_block "restart planningalerts" do
    block do
      require 'fileutils'
      FileUtils.touch("#{node[:planningalerts][stage][:install_path]}/current/planningalerts-app/tmp/restart.txt")
    end
    # Only run this when it gets notified by others
    action :nothing
  end

  template "#{@node[:planningalerts][stage][:install_path]}/current/planningalerts-app/app/models/configuration.rb" do
    source "configuration.rb.erb"
    variables :stage => stage
    notifies :create, resources(:ruby_block => "restart planningalerts")
  end

  template "#{@node[:apache][:dir]}/sites-available/#{@node[:planningalerts][stage][:name]}" do
    source "apache_#{stage}.conf.erb"
    mode 0644
    owner "root"
    group "wheel"
    variables :stage => stage
  end

  apache_site @node[:planningalerts][stage][:name]
end

remote_file @node[:planningalerts][:test][:apache_password_file] do
  source "htpasswd"
  mode 0644
end

# For deployments code is stored on the server. So, for testing make sure that you push the code
# to the test server

template "#{@node[:apache][:dir]}/sites-available/tickets.planningalerts" do
  source "apache_tickets.conf.erb"
  mode 0644
  owner "root"
  group "wheel"
end

apache_site "tickets.planningalerts"
