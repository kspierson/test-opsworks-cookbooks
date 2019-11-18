# Enable Nginx
service "nginx" do
  provider Chef::Provider::Service::Systemd
  supports :status => true, :restart => true, :reload => true
  action [ :enable ]
  #not_if { File.exists? "/opt/nginx/logs/nginx.pid" }
end

# Site Maintenance Page
directory "/opt/nginx/html" do
  mode 0755

  action :create
  not_if { File.directory? "/opt/nginx/html" }
end

cookbook_file '/opt/nginx/html/maintenance.html' do
  source 'maintenance.html'
  owner 'ec2-user'
  mode '0755'
  action :create
  notifies :reload, "service[nginx]"
end

# Deploy correct application
search("aws_opsworks_app").each do |app|
  if app['shortname'] == node[:application]

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
    end

    execute "Adding SSH key" do
      command "ssh-keyscan -H gitlab.com >> /home/ec2-user/.ssh/known_hosts"

      user "ec2-user"
    end

    if File.directory? "#{app['attributes']['document_root']}/server"
      execute "Deploying..." do
        command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git fetch --all && git reset --hard origin/#{app['app_source']['revision']}'"

        cwd "#{app['attributes']['document_root']}"
        user "ec2-user"
        notifies :reload, "service[nginx]", :delayed
      end
    else
      execute "Downloading and Deploying..." do
        command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} #{app['attributes']['document_root']}'"

        user "ec2-user"
        notifies :start, "service[nginx]", :delayed
      end
    end

    execute 'Symlink Node Installation' do
      command 'ln -sf /home/ec2-user/.nvm/versions/node/v10.15.2/bin/node /usr/local/bin/node'
      
      user "root"
    end

    bash "Install NPM Packages and build platform" do
      code <<-EOC
        source /home/ec2-user/.bashrc
        npm install
        npm run build
      EOC
      environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})

      cwd "#{app['attributes']['document_root']}"
      user "ec2-user"
      notifies :delete, 'cookbook_file[/opt/nginx/html/index.html]'
    end

    # ruby_block 'LOGGING DIRECTORY STRUCTURE' do
    #   block do
    #     Chef::Log.info(shell_out!("ls -la /home/ec2-user/.nvm").stdout)
    #     Chef::Log.info(shell_out!("ls -la /").stdout)
    #     Chef::Log.info(shell_out!("ls -la /proc").stdout)
    #     Chef::Log.info(shell_out!("ls -la /usr/local/bin").stdout)
    #     Chef::Log.info(shell_out!("ls -la /sys").stdout)
    #     Chef::Log.info(shell_out!("ls -la /home/ec2-user").stdout)
    #   end
    #   action :run
    # end

    # start the server
    # service "nginx" do
    #   #provider Chef::Provider::Service::Systemd
    #   #supports :status => true, :restart => true, :reload => true
    #   action [ :start ]
    #   #not_if { File.exists? "/opt/nginx/logs/nginx.pid" }
    # end

  end
end