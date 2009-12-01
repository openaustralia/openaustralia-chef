gem_package "thin"

template "/usr/local/etc/rc.d/thin" do
  source "thin.erb"
  mode 0555
end

service "thin" do
  supports :start => true, :stop => true, :status => true
  action [:enable, :start]
end
