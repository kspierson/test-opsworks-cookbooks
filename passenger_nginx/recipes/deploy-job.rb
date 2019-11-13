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
        command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git pull origin #{app['app_source']['revision']}'"

        cwd "#{app['attributes']['document_root']}"
        user "ec2-user"
      end
    else
      execute "Downloading and Deploying..." do
        command "ssh-agent bash -c 'ssh-add /home/ec2-user/.ssh/id_rsa; git clone -b #{app['app_source']['revision']} --single-branch #{app['app_source']['url']} #{app['attributes']['document_root']}'"

        user "ec2-user"
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
      minute '*'
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

    cron 'Generate RDS Token' do
      minute '*/14'
      command 'NODE_ENV=production flock -n /tmp/generateRDSToken.lock /usr/local/bin/node /var/www/server/build/server/src/scripts/generateRDSToken.js >> /home/ec2-user/logs/generateRDSToken.log'
      user 'ec2-user'
      only_if {File.exists?('/var/www/server/build/server/src/scripts/generateRDSToken.js')}
    end

    ruby_block 'Crontab Output' do
      block do
        Chef::Log.info(shell_out!("crontab -u ec2-user -l").stdout)
      end
      action :run
    end
    
  end
end