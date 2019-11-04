app = search("aws_opsworks_app").first

# # Add deploy user to rvm
# execute "Download Node from source and unpack/cleanup" do
#   command "curl -O https://nodejs.org/dist/v12.13.0/node-v12.13.0-linux-x64.tar.xz"
#   command "tar -xvf node-v12.13.0.tar.gz && rm node-v12.13.0.tar.gz"
#   user "root"
# end

# # Add deploy user to rvm
# execute "Configure, Make, and Install Node" do
#   command "./configure"
#   command "make"
#   command "sudo make install"
#   cwd "node-v12.13.0"
#   user "root"
# end

# Install Node
# execute "Installing NodeJS" do
#   command "rm -f /etc/yum.repos.d/nodesource-el.repo"
#   command "yum clean all"
#   command "yum -y remove nodejs"
#   command "curl –silent –location https://rpm.nodesource.com/setup_12.x | sudo bash –"
#   command "yum -y install nodejs"
#   #command "curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -"
#   #command "yum install -y nodejs --enablerepo=nodesource"

#   user "root"
#   not_if { File.exists? "/usr/local/bin/node" }
# end

# Install NVM and Node
# Install Node
# execute "Installing NVM" do
#   command "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash"
#   command ". ~/.nvm/nvm.sh"
#   #Chef::Log.info(shell_out!(". ~/.nvm/nvm.sh").stdout)
#   command "nvm install 10.15.2"

#   user "root"
#   #not_if { File.exists? "/usr/local/bin/node" }
# end

execute "Installing NVM" do
  command "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash"

  user "root"
  #not_if { File.exists? "/usr/local/bin/node" }
end

execute "ls -la" do
  Chef::Log.info(shell_out!("ls -la").stdout)

  user "root"
end

bash "Install NodeJS" do
  code <<-EOC
    source ~/.nvm/nvm.sh
    nvm install 10.15.2
  EOC

  user "root"
  # creates "/usr/local/nvm/#{node['nodejs']['version']}"
end

# execute "Configuring NVM" do
#   command ". ~/.nvm/nvm.sh"

#   user "root"
#   #not_if { File.exists? "/usr/local/bin/node" }
# end

# execute "LOG DIR" do
#   Chef::Log.info(shell_out!("ls -la").stdout)

#   user "root"
# end

# execute "Installing Node with NVM" do
#   command "nvm install 10.15.2"

#   user "root"
#   #not_if { File.exists? "/usr/local/bin/node" }
# end

# bash "Configuring NVM" do
#   code <<-EOF
#     export NVM_DIR="$HOME/.nvm"
#     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#     [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
#   EOF
#   user "root"
#   not_if { File.exists? "/opt/nginx/sbin/nginx" }
# end

# execute "Loading NVM and Installing Node" do
#   command "wget https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh /home/ec2-user/install.sh"
#   command "NVM_DIR=/usr/bin"
#   command "bash /home/ec2-user/install.sh"
#   command "mv /usr/bin/nvm.sh /usr/bin/nvm"
  
#   command "nvm install node 10.15.2"

#   user "root"
#   #not_if { File.exists? "/usr/local/bin/node" }
# end

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

# file '/root/.ssh/config' do
#   mode '0400'
#   content "Host gitserv
#   Hostname remote.server.com
#   IdentityFile ~/.ssh/id_rsa.github
#   IdentitiesOnly yes # see NOTES below"
# end

execute "Downloading and Deploying..." do
  command "ssh-agent bash -c 'ssh-add /root/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} .'"
  command "git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} ."

  user "root"
  cwd "#{app['app_source']['deploy_to']}"
  #not_if { File.exists? "/usr/local/bin/node" }
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


