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
end

planningalerts[:production][:html_root] = "#{planningalerts[:production][:install_path]}/current/planningalerts-app/docs" unless planningalerts[:production].has_key?(:html_root)
planningalerts[:test][:html_root] = "#{planningalerts[:test][:install_path]}/current/planningalerts-app/public" unless planningalerts[:test].has_key?(:html_root)

planningalerts[:test][:apache_password_file] = "#{planningalerts[:test][:install_path]}/shared/htpasswd" unless planningalerts[:test].has_key?(:apache_password_file)
