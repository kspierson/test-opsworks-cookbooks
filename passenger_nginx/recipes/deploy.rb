# Install Node
execute "Installing NodeJS" do
  command "curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -"
  command "sudo yum install -y nodejs"

  user "root"
  not_if { File.exists? "/usr/local/bin/node" }
end

# if node[:deploy].nil?
#   Chef::Log.info("No deployment..")
#   node[:deploy].each do |app, deploy|
#       Chef::Log.info("deploy -#{ app }-")
#   end
# elsif
#   Chef::Log.info("Deployment Exists!!!")
# end

# Download and deploy
file '/root/.ssh/id_rsa' do
  mode '0400'
  content "#{deploy['preview_free_movies']['scm']['ssh_key']}"
end

execute "Downloading and Deploying..." do
  command "git clone -b #{deploy['preview_free_movies']['scm']['revision']} --single-branch #{deploy['preview_free_movies']['scm']['repository']} ."
  command "sudo yum install -y nodejs"

  user "root"
  cwd "#{deploy['preview_free_movies']['deploy_to']}"
  not_if { File.exists? "/usr/local/bin/node" }
end

# git '/var/www' do
#   repository "#{deploy['preview_free_movies']['scm']['repository']}"
#   revision "#{deploy['preview_free_movies']['scm']['revision']}"
# end

# install NPM packages
execute 'Installing NPM Packages' do
  command 'npm prune'
  command 'npm install'
  cwd "#{deploy['preview_free_movies']['deploy_to']}"
end

# start the server
service "nginx" do
  provider Chef::Provider::Service::Systemd
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  not_if { File.exists? "/opt/nginx/logs/nginx.pid" }
end


