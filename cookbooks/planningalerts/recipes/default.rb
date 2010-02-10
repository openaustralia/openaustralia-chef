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

# For the time being only setting up the staging environment (:test)
[:production, :test].each do |stage|
  directory node[:planningalerts][stage][:install_path] do
    owner "matthewl"
    group "matthewl"
    mode 0755
    recursive true
  end
end

directory "#{node[:planningalerts][:production][:install_path]}/shared/data" do
  owner "www"
  group "www"
  # Making this writeable by everybody so that the mailer can be run as any user
  # Just a convenience thing. Really should look at this in more detail
  mode 0777
  recursive true
end

template "#{@node[:planningalerts][:production][:install_path]}/shared/config.php" do
  source "config.php.erb"
  owner "matthewl"
  group "matthewl"
  mode 0644
  variables :stage => :production
end

template "#{@node[:planningalerts][:production][:install_path]}/shared/htaccess" do
  source "htaccess.erb"
  owner "matthewl"
  group "matthewl"
  mode 0644
  variables :stage => :production
end

directory "#{@node[:planningalerts][:production][:install_path]}/shared/pids"

# TODO: Restart Passenger after deploy

# Going to try to use the new deploy resource instead of using capistrano. Let's see how we go
deploy_revision node[:planningalerts][:production][:install_path] do
  revision "production"
  repo "git://git.openaustralia.org/planningalerts.git"
  # This should not be set to :force_deploy for normal usage
  #action :force_deploy
  scm_provider Chef::Provider::Git
  # Override the default rails-like structure
  symlink_before_migrate "config.php" => "planningalerts-app/docs/include/config.php"
  purge_before_symlink ["planningalerts-app/docs/scrapers"]
  create_dirs_before_symlink ["planningalerts-parsers/tmp", "planningalerts-parsers/public"]
  symlinks "htaccess" => "planningalerts-app/docs/.htaccess",
    "../current/planningalerts-parsers/public" => "planningalerts-app/docs/scrapers",
    "pids" => "planningalerts-parsers/tmp/pids",
    "log" => "planningalerts-parsers/log"
  enable_submodules true
end

directory "#{node[:planningalerts][:test][:install_path]}/shared/" do
  owner "matthewl"
  group "matthewl"
end

directory "#{node[:planningalerts][:test][:install_path]}/shared/pids" do
  owner "matthewl"
  group "matthewl"
end

directory "#{node[:planningalerts][:test][:install_path]}/shared/log" do
  mode 0777
end

directory "#{node[:planningalerts][:test][:install_path]}/shared/config"

template "#{@node[:planningalerts][:test][:install_path]}/shared/config/database.yml" do
  source "database.yml.erb"
end

deploy_revision node[:planningalerts][:test][:install_path] do
  revision "test"
  user "matthewl"
  group "matthewl"
  repo "git://git.openaustralia.org/planningalerts.git"
  # This should not be set to :force_deploy for normal usage
  #action :force_deploy
  scm_provider Chef::Provider::Git
  symlink_before_migrate "config/database.yml" => "planningalerts-app/config/database.yml"
  purge_before_symlink ["planningalerts-app/log", "planningalerts-app/tmp/pids", "planningalerts-app/public/system"]
  create_dirs_before_symlink ["planningalerts-app/tmp", "planningalerts-app/public", "planningalerts-app/config",
    "planningalerts-parsers/public"]
  symlinks "system" => "planningalerts-app/public/system", "pids" => "planningalerts-app/tmp/pids",
    "log" => "planningalerts-app/log",
    "../current/planningalerts-parsers/public" => "planningalerts-app/public/scrapers"
  enable_submodules true
end

# TODO: We need to kick passenger when we change this file
template "#{@node[:planningalerts][:test][:install_path]}/current/planningalerts-app/app/models/configuration.rb" do
  source "configuration.rb.erb"
  variables :stage => :test
end

[:production, :test].each do |stage|
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
