# JOB SERVER SETUP

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
  environment ({'VANTA_KEY' => 'fggycre8ynt1fnwfn004vx0drq58j9g3fddrc9gpvngx7nxegwt0'})

  user "ec2-user"
  regex = Regexp.escape("vanta.x86_64")
    not_if { `bash -c "yum list installed vanta"`.lines.grep(/^#{regex}/).count > 0 }
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

