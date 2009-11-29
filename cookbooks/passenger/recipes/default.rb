gem_package "passenger" do
  version node[:passenger][:version]
end
 
execute "passenger_module" do
  command 'passenger-install-apache2-module -a'
  creates node[:passenger][:module_path]
end
