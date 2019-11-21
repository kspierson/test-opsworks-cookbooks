# Remove Cron Jobs
cron 'Screening Snapshot' do
  # minute '*/7'
  # command 'NODE_ENV=production flock -n /tmp/takeScreeningSnapshot.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/takeScreeningSnapshot.js >> /home/ec2-user/logs/snapshotCron.log'
  user 'ec2-user'
  action :delete
end

cron 'Screening Reminder' do
  # minute '*/30'
  # command 'NODE_ENV=production flock -n /tmp/sendScreeningReminder.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/sendScreeningReminder.js >> /home/ec2-user/logs/reminderCron.log'
  user 'ec2-user'
  action :delete
end

cron 'Create DB Snapshot' do
  # minute '*'
  # command 'NODE_ENV=production flock -n /tmp/takeDbSnapshot.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/takeDbSnapshot.js >> /home/ec2-user/logs/dbSnapshotCron.log'
  user 'ec2-user'
  action :delete
end

cron 'Update Screening Invitation' do
  # minute '*/30'
  # command 'NODE_ENV=production flock -n /tmp/updateScreeningInvitation.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/updateScreeningInvitation.js >> /home/ec2-user/logs/screeningInvitationCron.log'
  user 'ec2-user'
  action :delete
end

cron 'Generate RDS Token' do
  # minute '*/14'
  # command 'NODE_ENV=production flock -n /tmp/generateRDSToken.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/generateRDSToken.js >> /home/ec2-user/logs/generateRDSToken.log'
  user 'ec2-user'
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