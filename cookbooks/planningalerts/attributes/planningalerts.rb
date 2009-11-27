planningalerts Mash.new unless attribute?("planningalerts")

[:production, :test].each do |stage|
  planningalerts[stage] = Mash.new unless planningalerts.has_key?(stage)
end

planningalerts[:production][:subdomain] = "www" unless planningalerts[:production].has_key?(:subdomain)
planningalerts[:test][:subdomain] = "test" unless planningalerts[:test].has_key?(:subdomain)

[:production, :test].each do |stage|
  planningalerts[stage][:name] = "#{planningalerts[stage][:subdomain]}.planningalerts" unless planningalerts[stage].has_key?(:name)
  planningalerts[stage][:virtual_host_name] = "#{planningalerts[stage][:subdomain]}.#{planningalerts[:domain]}" unless planningalerts[stage].has_key?(:virtual_host_name)
  planningalerts[stage][:install_path] = "/www/#{planningalerts[stage][:name]}/app" unless planningalerts[stage].has_key?(:install_path)
  planningalerts[stage][:html_root] = "#{planningalerts[stage][:install_path]}/current/docs" unless planningalerts[stage].has_key?(:html_root)
end

# TODO: Change this to something to works!
planningalerts[:test][:apache_password_file] = "#{planningalerts[:test][:install_path]}/shared/htpasswd" unless planningalerts[:test].has_key?(:apache_password_file)
