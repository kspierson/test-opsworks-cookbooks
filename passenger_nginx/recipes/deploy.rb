app = search("aws_opsworks_app").first

directory "/home/ec2-user/.ssh" do
  mode 0700
  action :create
  user "ec2-user"
  not_if { File.directory? "/home/ec2-user/.ssh" }
end

# Download and deploy
file '/home/ec2-user/.ssh/id_rsa' do
  owner 'ec2-user'
  mode '0400'
  content "#{app['app_source']['ssh_key']}"
end

directory "#{app['attributes']['document_root']}" do
  owner 'ec2-user'
  mode 0755
  action :create
  #not_if { File.directory? "#{app['attributes']['document_root']}" }
end

execute "Adding SSH key" do
  command "ssh-keyscan -H gitlab.com >> /home/ec2-user/.ssh/known_hosts"

  user "ec2-user"
  #not_if { File.exists? "/usr/local/bin/node" }
end

execute "Downloading and Deploying..." do
  command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} #{app['attributes']['document_root']}'"
  #command "GIT_SSH_COMMAND=\"ssh -i /root/.ssh/id_rsa\" git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} ."
  #environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})

  user "ec2-user"
  #cwd "#{app['attributes']['document_root']}"
  not_if { File.directory? "#{app['attributes']['document_root']}/server" }
end

execute 'Symlink Node Installation' do
  #command 'npm prune'
  command 'ln -sf /home/ec2-user/.nvm/versions/node/v10.15.2/bin/node /usr/local/bin/node'
  
  user "root"
end

# install NPM packages
# execute 'Installing NPM Packages' do
#   #command 'npm prune'
#   command 'npm install'
#   environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})
  
#   cwd "#{app['attributes']['document_root']}"
#   user "ec2-user"
# end

bash "Install NPM Packages" do
  code <<-EOC
    source /home/ec2-user/.bashrc
    npm install
  EOC
  environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})

  cwd 
  user "#{app['attributes']['document_root']}"
  #not_if { File.exists? "/home/ec2-user/.nvm" }
  # creates "/usr/local/nvm/#{node['nodejs']['version']}"
end

# execute "ls -la" do
#   #Chef::Log.info(shell_out!("ls -la").stdout)
#   #Chef::Log.info(shell_out!("ls -la /home").stdout)
#   Chef::Log.info(shell_out!("ls -la /home/ec2-user").stdout)
#   Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm").stdout)
#   Chef::Log.info(shell_out!("ls -la /usr/bin").stdout)
#   Chef::Log.info(shell_out!("ls -la /usr/local/bin").stdout)
#   #Chef::Log.info(shell_out!("cat /home/ec2-user/.bashrc").stdout)
#   #Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm/versions/node/v10.15.2").stdout)
#   #Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm/versions/node/v10.15.2/bin").stdout)

#   user "ec2-user"
# end

ruby_block 'LOGGING DIRECTORY STRUCTURE' do
  block do
      #Chef::Log.info(shell_out!("ls -la").stdout)
  #Chef::Log.info(shell_out!("ls -la /home").stdout)
  Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm").stdout)
    Chef::Log.info(shell_out!("ls -la /").stdout)
    Chef::Log.info(shell_out!("ls -la /proc").stdout)
    Chef::Log.info(shell_out!("ls -la /usr/local/bin").stdout)
    Chef::Log.info(shell_out!("ls -la /sys").stdout)
    Chef::Log.info(shell_out!("ls -la /home/ec2-user").stdout)
  #Chef::Log.info(shell_out!("/usr/local/bin/node -v").stdout)
  #Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm/versions/node/v10.15.2").stdout)
  #Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm/versions/node/v10.15.2/bin").stdout)
  end
  action :run
end

# start the server
service "nginx" do
  # Chef::Log.info(shell_out!("ls -la /home/ec2-user").stdout)
  # Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm").stdout)
  # Chef::Log.info(shell_out!("ls -la /usr/bin").stdout)
  # Chef::Log.info(shell_out!("ls -la /usr/local/bin").stdout)
  provider Chef::Provider::Service::Systemd
  user 'ec2-user'
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  #not_if { File.exists? "/opt/nginx/logs/nginx.pid" }
end


