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

    execute "Adding Bitbucket SSH key" do
      command "ssh-keyscan -H bitbucket.org >> /home/ec2-user/.ssh/known_hosts"

      user "ec2-user"
    end

    if File.directory? "#{app['attributes']['document_root']}/server"
      execute "Deploying..." do
        command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git fetch -f -u origin #{app['app_source']['revision']}:#{app['app_source']['revision']} && git checkout -f #{app['app_source']['revision']}'"

        cwd "#{app['attributes']['document_root']}"
        user "ec2-user"
      end
    else
      execute "Downloading and Deploying..." do
        command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} #{app['attributes']['document_root']}'"

        user "ec2-user"
      end
    end

    bash "Install NPM Packages and build platform" do
      code <<-EOC
        source /home/ec2-user/.bashrc
        rm -rf node_modules
        npm install
        npm run build
      EOC
      environment ({'HOME' => '/home/ec2-user', 'USER' => 'ec2-user'})

      cwd "#{app['attributes']['document_root']}"
      user "ec2-user"
    end

    # Cron Logs Directory
    directory "/home/ec2-user/logs" do
      owner 'ec2-user'
      mode 0755
      action :create
      not_if { File.directory? "/home/ec2-user/logs" }
    end

    # Add Cron Jobs
    cron 'Screening Snapshot' do
      minute '*/7'
      command 'NODE_ENV=production flock -n /tmp/takeScreeningSnapshot.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/takeScreeningSnapshot.js >> /home/ec2-user/logs/snapshotCron.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/takeScreeningSnapshot.js')}
    end

    cron 'Screening Reminder' do
      minute '*/30'
      command 'NODE_ENV=production flock -n /tmp/sendScreeningReminder.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/sendScreeningReminder.js >> /home/ec2-user/logs/reminderCron.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/sendScreeningReminder.js')}
    end

    cron 'Create DB Snapshot' do
      minute '0'
      hour '7'
      command 'NODE_ENV=production flock -n /tmp/takeDbSnapshot.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/takeDbSnapshot.js >> /home/ec2-user/logs/dbSnapshotCron.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/takeDbSnapshot.js')}
    end

    cron 'Update Screening Invitation' do
      minute '*/30'
      command 'NODE_ENV=production flock -n /tmp/updateScreeningInvitation.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/updateScreeningInvitation.js >> /home/ec2-user/logs/screeningInvitationCron.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/updateScreeningInvitation.js')}
    end

    cron 'Send Scheduled Emails' do
      minute '*/5'
      command 'NODE_ENV=production flock -n /tmp/sendScheduledEmails.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/sendScheduledEmails.js >> /home/ec2-user/logs/scheduledEmailsCron.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/sendScheduledEmails.js')}
    end

    cron 'Update Membership' do
      minute '0'
      hour '6'
      command 'NODE_ENV=production flock -n /tmp/updateMembership.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/updateMembership.js >> /home/ec2-user/logs/updateMembershipCron.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/updateMembership.js')}
    end

    # cron 'Generate RDS Token' do
    #   minute '*/14'
    #   command 'NODE_ENV=production flock -n /tmp/generateRDSToken.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/generateRDSToken.js >> /home/ec2-user/logs/generateRDSToken.log'
    #   user 'ec2-user'
    #   only_if {File.exists?('/var/www/server/build/server/src/scripts/generateRDSToken.js')}
    # end

  end
end