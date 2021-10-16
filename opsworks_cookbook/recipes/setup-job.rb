# JOB SERVER SETUP
instance = search("aws_opsworks_instance", "self:true").first

execute "yum update" do
  command "yum update -y"
  user "root"
end

# Install basic packages
%w(git curl gpg gcc gcc-c++ make glibc-devel openssl openssl-devel openssl-libs libcurl libcurl-devel pcre-devel).each do |pkg|
  yum_package pkg
end

# Install Vanta Agent
execute "Installing Vanta Agent" do
  command "curl -o- https://raw.githubusercontent.com/VantaInc/vanta-agent-scripts/master/install-linux.sh | bash"
  environment ({'VANTA_KEY' => "#{node['vanta_key']}"})

  user "ec2-user"
  regex = Regexp.escape("vanta.x86_64")
  not_if { `bash -c "yum list installed vanta"`.lines.grep(/^#{regex}/).count > 0 }
end

# Download DarkTrace
execute "Download Darktrace" do
  command "aws s3 cp s3://seasi-deps/darktrace/#{node['darktrace']['installer']}.rpm /home/ec2-user/#{node['darktrace']['installer']}.rpm"
  user "ec2-user"
  not_if { File.exists? "/home/ec2-user/#{node['darktrace']['installer']}.rpm" }
end

# Install DarkTrace
execute "Install Darktrace" do
  command "yum install -y /home/ec2-user/#{node['darktrace']['installer']}.rpm"
  user "root"
  not_if { File.exists? "/etc/darktrace/ossensor.cfg" }
end

directory "/etc/darktrace" do
  mode 0755
  action :create
  not_if { File.directory? "/etc/darktrace" }
end

# Configure DarkTrace
template "/etc/darktrace/ossensor.cfg" do
  source "ossensor.cfg.erb"
  variables(
    darktrace_key: node[:darktrace][:key],
    darktrace_ip: node[:darktrace][:ip],
    ipaddress: instance[:private_ip]
  )
  #not_if { File.exists? "/etc/darktrace/ossensor.cfg" }
end

# Enable and Start Darktrace
service "darktrace-ossensor" do
  provider Chef::Provider::Service::Systemd

  action [ :enable, :start ]
end

# Install NVM
execute "Installing NVM" do
  command "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash"
  environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})

  user "ec2-user"
  not_if { File.exists? "/home/ec2-user/.nvm" }
end

# Install NodeJS
bash "Install NodeJS" do
  code <<-EOC
    source /home/ec2-user/.nvm/nvm.sh
    nvm install #{node['nodejs_version']}
  EOC
  environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})

  user "ec2-user"
  not_if { File.exists? "/home/ec2-user/.nvm/versions/node/v#{node['nodejs_version']}/bin/node" }
end

execute 'Symlink Node Installation' do
  command "ln -sf /home/ec2-user/.nvm/versions/node/v#{node['nodejs_version']}/bin/node /usr/local/bin/node"
  
  user "root"
end

