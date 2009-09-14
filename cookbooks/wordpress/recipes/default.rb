include_recipe "apache"
include_recipe "php"

directory "/www/blog"

unless File.exists?("/www/blog/html")
  puts "Downloading and installing Wordpress..."
  remote_file "wordpress" do
    path "/tmp/wordpress.tar.gz"
    source "http://wordpress.org/wordpress-2.8.4.tar.gz"
    not_if { File.exists?(path) }
  end

  # Hmmm... Making the untar verbose (with the 'v' option) makes this command hang on FreeBSD
  execute "untar-wordpress" do
    command "(cd /tmp; tar zxf /tmp/wordpress.tar.gz)"
  end
  
  execute "install-wordpress" do
    command "mv /tmp/wordpress /www/blog/html/"
  end
end


template "/www/blog/html/wp-config.php" do
  source "wp-config.php.erb"
  mode 0644
end

template "site.conf" do
  path "/usr/local/etc/apache22/sites-available/blog"
  source "httpd.conf.erb"
  mode 0644
  owner "root"
  group "wheel"
end
  
apache_site "blog"

# Update php so that plugin install/update for Wordpress can work via sftp
package "pecl-ssh2" do
  source "ports"
end
