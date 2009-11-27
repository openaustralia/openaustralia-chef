#   create database $database_name character set utf8;
#   grant all privileges on $database_name.* to '$user'@'localhost' identified by '$password';
#   flush privileges;

require_recipe 'apache'
require_recipe 'php'
require_recipe 'mysql'

# For the time being only setting up the staging environment (:test)
[:test].each do |stage|
  directory node[:planningalerts][stage][:install_path] do
    owner "matthewl"
    group "matthewl"
    mode 0755
    recursive true
  end
end

template "#{@node[:planningalerts][:test][:install_path]}/shared/config.php" do
  source "config.php.erb"
  owner "matthewl"
  group "matthewl"
  mode 0644
end

template "#{@node[:planningalerts][:test][:install_path]}/shared/htaccess" do
  source "htaccess.erb"
  owner "matthewl"
  group "matthewl"
  mode 0644  
end


# Going to try to use the new deploy resource instead of using capistrano. Let's see how we go
deploy_revision node[:planningalerts][:test][:install_path] do
  # Probably should change this to something like a "production" branch so that we have to merge master
  # into the production branch before it will deploy
  revision "HEAD"
  repo "git://git.openaustralia.org/planningalerts-app.git"
  # This should not be set to :force_deploy for normal usage
  action :force_deploy
  scm_provider Chef::Provider::Git
  # Override the default rails-like structure
  symlink_before_migrate "config.php" => "docs/include/config.php", "htaccess" => "docs/.htaccess"
  purge_before_symlink []
  create_dirs_before_symlink []
  symlinks "foo" => "bar"
end

template "#{@node[:apache][:dir]}/sites-available/#{@node[:planningalerts][:test][:name]}" do
  source "apache_test.conf.erb"
  mode 0644
  owner "root"
  group "wheel"
end

apache_site @node[:planningalerts][:test][:name]

# For deployments code is stored on the server. So, for testing make sure that you push the code
# to the test server
