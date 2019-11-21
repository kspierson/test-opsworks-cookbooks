# Remove Cron Jobs
cron 'Screening Snapshot' do
  user 'ec2-user'
  action :delete
end

cron 'Screening Reminder' do
  user 'ec2-user'
  action :delete
end

cron 'Create DB Snapshot' do
  user 'ec2-user'
  action :delete
end

cron 'Update Screening Invitation' do
  user 'ec2-user'
  action :delete
end

cron 'Generate RDS Token' do
  user 'ec2-user'
  action :delete
end

# Remove Deployment
execute "Removing Deployment" do
  command "rm -rf /var/www"

  #user "ec2-user"
end