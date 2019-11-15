# Ruby & RVM
default['passenger_nginx']['ruby_version'] = "2.3.3"
default['passenger_nginx']['rvm']['rvm_shell'] = '/etc/profile.d/rvm.sh'

# Nginx
default['passenger_nginx']['nginx']['extra_configure_flags'] = ""
default['passenger_nginx']['nginx']['worker_processes'] = 'auto'
default['passenger_nginx']['nginx']['worker_connections'] = 100000
default['passenger_nginx']['nginx']['worker_rlimit_nofile'] = 102400
default['passenger_nginx']['nginx']['user'] = 'root'
default['passenger_nginx']['nginx']['access_log'] = 'logs/access.log'
default['passenger_nginx']['nginx']['error_log'] = 'logs/error.log'
default['passenger_nginx']['nginx']['http2'] = false

# Passenger
default['passenger_nginx']['passenger']['version'] = '6.0.4'
default['passenger_nginx']['passenger']['max_pool_size'] = 12
default['passenger_nginx']['passenger']['min_instances'] = 12
default['passenger_nginx']['passenger']['pool_idle_time'] = 300
default['passenger_nginx']['passenger']['max_instances_per_app'] = 0
default['passenger_nginx']['passenger']['rolling_restarts'] = nil

# a list of URL's to pre-start.
#default['passenger_nginx']['passenger']['pre_start'] = []

# Applications
default['passenger_nginx']['apps'] = []

# Node
default['nodejs']['version'] = '10.15.2'

