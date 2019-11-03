app = search("aws_opsworks_app").first

# # Install Node
# execute "Installing NodeJS" do
#   command "curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -"
#   command "sudo yum install -y nodejs"

#   user "root"
#   not_if { File.exists? "/usr/local/bin/node" }
# end

# Install NVM and Node
# Install Node
execute "Installing NVM and Node" do
  command "curl -sL https://rpm.nodesource.com/setup_12.x | bash -"
  command "yum install -y nodejs"
  command

  user "root"
  not_if { File.exists? "/usr/local/bin/node" }
end

# if node
#   Chef::Log.info("Reading node...")
#   node.each do |app, deploy|
#       Chef::Log.info("node -#{ app }-")
#   end
# elsif
#   Chef::Log.info("NO NODE")
# end

# Download and deploy
file '/root/.ssh/id_rsa' do
  mode '0400'
  content "#{app['app_source']['ssh_key']}"
end

execute "Downloading and Deploying..." do
  command "git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} ."
  command "sudo yum install -y nodejs"

  user "root"
  cwd "#{app['app_source']['deploy_to']}"
  not_if { File.exists? "/usr/local/bin/node" }
end

# git '/var/www' do
#   repository "#{app['app_source']['repository']}"
#   revision "#{app['app_source']['revision']}"
# end

# install NPM packages
execute 'Installing NPM Packages' do
  command 'npm prune'
  command 'npm install'
  cwd "#{app['attributes']['document_root']}"
end

# start the server
service "nginx" do
  provider Chef::Provider::Service::Systemd
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  not_if { File.exists? "/opt/nginx/logs/nginx.pid" }
end


