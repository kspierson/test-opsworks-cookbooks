# WEB SERVER SETUP

execute "yum update" do
  command "yum update -y"
  user "root"
end

# Install basic packages
%w(git curl gpg gcc gcc-c++ make glibc-devel openssl openssl-devel openssl-libs libcurl libcurl-devel pcre-devel).each do |pkg|
  yum_package pkg
end

execute "Installing GPG keys" do
  command "sudo gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"

  user "root"
  not_if { File.exists? "/usr/local/rvm/bin/rvm" }
end

# Install RVM
execute "Installing RVM and Ruby" do
  command "curl -L https://get.rvm.io | bash -s stable"
  user "root"
  not_if { File.exists? "/usr/local/rvm/bin/rvm" }
end

# Add deploy user to rvm
# execute "Add deploy user to RVM" do
#   command "usermod -a -G rvm #{node['passenger_nginx']['nginx']['user']}"
#   user "root"
# end

# Install Ruby
bash "Install Ruby" do
  code "source /etc/profile.d/rvm.sh && rvm install #{node['passenger_nginx']['ruby_version']}"
  user "root"
  not_if { Dir.exists? "/usr/local/rvm/rubies/ruby-#{node['passenger_nginx']['ruby_version']}" }
end

# Set default Ruby
bash "Set default Ruby" do
  code "source /etc/profile.d/rvm.sh && rvm --default use #{node['passenger_nginx']['ruby_version']}"
end


# Check for if we are installing Passenger Enterprise
# passenger_enterprise = !!node['passenger_nginx']['passenger']['enterprise_download_token']

# if passenger_enterprise
#   bash "Installing Passenger Enterprise Edition" do
#     code <<-EOF
#     source #{node['passenger_nginx']['rvm']['rvm_shell']}
#     gem install --source https://download:#{node['passenger_nginx']['passenger']['enterprise_download_token']}@www.phusionpassenger.com/enterprise_gems/ passenger-enterprise-server -v #{node['passenger_nginx']['passenger']['version']} --no-document
#     EOF
#     user "root"

#     regex = Regexp.escape("passenger-enterprise-server (#{node['passenger_nginx']['passenger']['version']})")
#     not_if { `bash -c "source #{node['passenger_nginx']['rvm']['rvm_shell']} && gem list"`.lines.grep(/^#{regex}/).count > 0 }
#   end
# else
  # Install Passenger open source
  bash "Installing Passenger Open Source Edition" do
    code <<-EOF
    source #{node['passenger_nginx']['rvm']['rvm_shell']}
    gem install passenger -v #{node['passenger_nginx']['passenger']['version']} --no-document
    EOF
    user "root"

    regex = Regexp.escape("passenger (#{node['passenger_nginx']['passenger']['version']})")
    not_if { `bash -c "source #{node['passenger_nginx']['rvm']['rvm_shell']} && gem list"`.lines.grep(/^#{regex}/).count > 0 }
  end
# end

bash "Installing passenger nginx module and nginx from source" do
  code <<-EOF
  source #{node['passenger_nginx']['rvm']['rvm_shell']}
  passenger-install-nginx-module --auto --prefix=/opt/nginx --auto-download --extra-configure-flags="--with-http_gzip_static_module #{node['passenger_nginx']['nginx']['http2'] ? "--with-http_v2_module" : ""} #{node['passenger_nginx']['nginx']['extra_configure_flags']}"
  EOF
  user "root"
  not_if { File.exists? "/opt/nginx/sbin/nginx" }
end

# Create the config
# if passenger_enterprise
#   passenger_root = "/usr/local/rvm/gems/ruby-#{node['passenger_nginx']['ruby_version']}/gems/passenger-enterprise-server-#{node['passenger_nginx']['passenger']['version']}"
# else
  passenger_root = "/usr/local/rvm/gems/ruby-#{node['passenger_nginx']['ruby_version']}/gems/passenger-#{node['passenger_nginx']['passenger']['version']}"
# end

template "/opt/nginx/conf/nginx.conf" do
  source "nginx.conf.erb"
  variables({
    :ruby_version => node['passenger_nginx']['ruby_version'],
    :rvm => node['rvm'],
    :root_dir => node['root_dir'],
    :passenger_root => passenger_root,
    :passenger => node['passenger_nginx']['passenger'],
    :nginx => node['passenger_nginx']['nginx']
  })
end

# Configure Nginx Service (systemd)
systemd_unit 'nginx.service' do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=The NGINX HTTP and reverse proxy server
  After=syslog.target network.target remote-fs.target nss-lookup.target

  [Service]
  Type=forking
  PIDFile=/opt/nginx/logs/nginx.pid
  ExecStartPre=/opt/nginx/sbin/nginx -t
  ExecStart=/opt/nginx/sbin/nginx
  ExecReload=/opt/nginx/sbin/nginx -s reload
  ExecStop=/bin/kill -s QUIT $MAINPID
  PrivateTmp=true

  [Install]
  WantedBy=multi-user.target
  EOU

  action [:create, :enable]
end

# Add log rotation
cookbook_file "/etc/logrotate.d/nginx" do
  source "nginx.logrotate"
  action :create
end

directory "/opt/nginx/conf/sites-enabled" do
  mode 0755
  action :create
  not_if { File.directory? "/opt/nginx/conf/sites-enabled" }
end

directory "/opt/nginx/conf/sites-available" do
  mode 0755
  action :create
  not_if { File.directory? "/opt/nginx/conf/sites-available" }
end

# Add any applications that we need
node['passenger_nginx']['apps'].each do |app|

  template "/opt/nginx/conf/sites-available/#{app[:name]}" do
    mode 0744
    action :create

    # Create the conf
    if app[:config_source]
      source app[:config_source]
    else
      source "nginx_app.conf.erb"
    end

    # If we are completely overriding the cookbook, use this:
    if app[:config_cookbook]
      cookbook app[:config_cookbook]
    end

    # Read custom config
    custom_config = if app['custom_config'] && app['custom_config'].kind_of?(Array)
      app['custom_config'].join "\n"
    else
      app['custom_config']
    end

    variables(
      listen: app['listen'] || 80,
      listen_redirect: app['listen_redirect'] || 80,
      server_name: app['server_name'] || nil,
      root: app['root'] || "/opt/nginx/html",
      ssl_certificate: app['ssl_certificate'] || nil,
      ssl_certificate_key: app['ssl_certificate_key'] || nil,
      redirect_http_https: app['redirect_http_https'] || false,
      http2: app['http2'] || false,
      ruby_version: app['ruby_version'] || node['passenger_nginx']['ruby_version'] || nil,
      ruby_gemset: app['ruby_gemset'] || nil,
      app_env: app['app_env'] || nil,
      passenger_min_instances: app['passenger_min_instances'] || nil,
      passenger_max_instances: app['passenger_max_instances'] || nil,
      passenger_concurrency_model: app['passenger_concurrency_model'] || nil,
      passenger_thread_count: app['passenger_thread_count'] || nil,
      access_log: app['access_log'] || nil,
      error_log: app['error_log'] || nil,
      custom_config: custom_config || nil,
      client_max_body_size: app['client_max_body_size'] || nil,
      client_body_buffer_size: app['client_body_buffer_size'] || nil,
      gzip_static: app['gzip_static'] || false
    )
  end

  # Symlink the conf
  link "/opt/nginx/conf/sites-enabled/#{app[:name]}" do
    to "/opt/nginx/conf/sites-available/#{app[:name]}"
  end

  # Create the ruby gemset
  if node['passenger_nginx']['ruby_version'] && app['ruby_gemset']
    bash "Create Ruby Gemset" do
      code <<-EOF
      source #{node['passenger_nginx']['rvm']['rvm_shell']}
      rvm ruby-#{node['passenger_nginx']['ruby_version']} do rvm gemset create #{app['ruby_gemset']}
      EOF
      user "root"
      not_if { File.directory? "/usr/local/rvm/gems/ruby-#{node['passenger_nginx']['ruby_version']}@#{app['ruby_gemset']}" }
    end
  end
end

# Install NVM
execute "Installing NVM" do
  command "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash"
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

# execute 'Set NodeJS Max HTTP Header Size' do
#   command "NODE_OPTIONS='--max-http-header-size=81920'"
  
#   user "root"
# end

execute 'Symlink Node Installation' do
  command "ln -sf /home/ec2-user/.nvm/versions/node/v#{node['nodejs_version']}/bin/node /usr/local/bin/node"
  
  user "root"
end

