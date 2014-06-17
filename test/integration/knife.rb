chef_repo = File.join(File.dirname(__FILE__), "..")

#chef_server_url "http://127.0.0.1:8889"
#chef_server_url "http://#{`hostname`.chomp}:8889"
chef_server_url "http://#{`hostname`.chomp}:4545"
node_name       ENV['USER']
client_key      File.join(ENV['HOME'], ".chef", "#{ENV['USER']}.pem")
cookbook_path   "#{chef_repo}/cookbooks"
cache_type      "BasicFile"
cache_options   :path => "#{chef_repo}/checksums"
