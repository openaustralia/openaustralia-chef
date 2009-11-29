require_recipe 'apache'

gem_package "passenger" do
  version node[:passenger][:version]
end
 
execute "passenger_module" do
  command 'passenger-install-apache2-module -a'
  creates node[:passenger][:module_path]
end

template "#{node[:apache][:dir]}/mods-available/passenger.load" do
  source "passenger.load.erb"
  mode 0755
end

template "#{node[:apache][:dir]}/mods-available/passenger.conf" do
  source "passenger.conf.erb"
  mode 0755
end
 
apache_module "passenger"