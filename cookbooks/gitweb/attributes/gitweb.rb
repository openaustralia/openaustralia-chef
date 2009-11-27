gitweb_subdomain "git" unless attribute?("gitweb_subdomain")
gitweb_root "/www/#{gitweb_subdomain}" unless attribute?("gitweb_root")
gitweb_domain "#{gitweb_subdomain}.#{openaustralia[:domain]}" unless attribute?("gitweb_domain")
