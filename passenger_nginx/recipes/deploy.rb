app = search("aws_opsworks_app").first

execute "Installing NVM" do
  command "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash"

  user "root"
  #not_if { File.exists? "/usr/local/bin/node" }
end

bash "Install NodeJS" do
  code <<-EOC
    source ~/.nvm/nvm.sh
    nvm install 10.15.2
  EOC

  user "root"
  # creates "/usr/local/nvm/#{node['nodejs']['version']}"
end

# Download and deploy
file '/root/.ssh/id_rsa' do
  mode '0400'
  content "#{app['app_source']['ssh_key']}"
end

directory "#{app['attributes']['document_root']}" do
  mode 0755
  action :create
  not_if { File.directory? "#{app['attributes']['document_root']}" }
end

execute "ls -la" do
  # Chef::Log.info(shell_out!("ls -la").stdout)
  # Chef::Log.info(shell_out!("ls -la /usr/bin").stdout)
  # Chef::Log.info(shell_out!("ls -la /usr/local/bin").stdout)
  Chef::Log.info(shell_out!("ls -la ~/.nvm/versions/node/").stdout)
  # Chef::Log.info(shell_out!("ls -la ~").stdout)
  #Chef::Log.info(shell_out!("nvm which node").stdout)

  user "root"
end

execute "Adding SSH key" do
  command "ssh-keyscan -H gitlab.com >> root/.ssh/known_hosts"

  user "root"
  #not_if { File.exists? "/usr/local/bin/node" }
end

execute "Downloading and Deploying..." do
  command "ssh-agent bash -c 'ssh-add /root/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} #{app['attributes']['document_root']}'"
  #command "GIT_SSH_COMMAND=\"ssh -i /root/.ssh/id_rsa\" git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} ."

  user "root"
  #cwd "#{app['attributes']['document_root']}"
  not_if { File.directory? "#{app['attributes']['document_root']}" }
end

# install NPM packages
execute 'Installing NPM Packages' do
  #command 'npm prune'
  command 'npm install'
  
  cwd "#{app['attributes']['document_root']}"
  user "root"
end

# start the server
service "nginx" do
  provider Chef::Provider::Service::Systemd
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  not_if { File.exists? "/opt/nginx/logs/nginx.pid" }
end


