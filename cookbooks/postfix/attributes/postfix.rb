postfix Mash.new unless attribute?("postfix")
postfix[:myhostname] = "www.#{openaustralia[:domain]}" unless postfix.has_key?(:myhostname)
postfix[:mydomain] = openaustralia[:domain] unless postfix.has_key?(:mydomain)
