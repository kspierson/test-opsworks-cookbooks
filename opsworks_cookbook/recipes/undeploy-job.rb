# Remove Cron Jobs
cron 'Screening Snapshot' do
  action :delete
end

cron 'Screening Reminder' do
  action :delete
end

cron 'Create DB Snapshot' do
  action :delete
end

cron 'Update Screening Invitation' do
  action :delete
end

cron 'Generate RDS Token' do
  action :delete
end

# Remove Deployment
execute "Removing Deployment" do
  command "rm -rf /var/www"

  #user "ec2-user"
end

ruby_block 'Crontab Output' do
  block do
    Chef::Log.info(shell_out!("crontab -u ec2-user -l").stdout)
  end
  action :run
end