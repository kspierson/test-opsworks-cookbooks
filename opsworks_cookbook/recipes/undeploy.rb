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

# Remove Deployment
execute "Removing Deployment" do
  command "rm -rf /var/www"

  #user "ec2-user"
end