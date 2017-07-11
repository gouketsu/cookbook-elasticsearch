[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

Erubis::Context.send(:include, Extensions::Templates)

elasticsearch = "elasticsearch-#{node['elasticsearch']['version']}"

Chef::Log.debug "Installation mode #{node['elasticsearch']['installation']['mode']}"

if node['elasticsearch']['esmajor'].to_i >= 5
  node.default['elasticsearch']['bootstrap']['memory_lock'] = node['elasticsearch']['bootstrap']['mlockall']
  if node['elasticsearch']['limits']['nofile'] < 65536
    node.default['elasticsearch']['limits']['nofile'] = 65536
  end
end

if node['elasticsearch']['installation']['mode'] == 'pkg'
  case node['platform']
    when "ubuntu","debian"
      include_recipe "elasticsearch::deb"
    when "redhat","fedora", "centos"
      include_recipe "elasticsearch::rpm" 
  end
end


if node['elasticsearch']['installation']['mode'] == 'tar'
  include_recipe "elasticsearch::curl"
  include_recipe "ark"

  # Create user and group
  #
  group node['elasticsearch']['user'] do
    gid node['elasticsearch']['gid']
    action :create
    system true
  end

  user node['elasticsearch']['user'] do
    comment 'ElasticSearch User'
    home    "#{node['elasticsearch']['dir']}/elasticsearch"
    shell   '/bin/bash'
    uid     node['elasticsearch']['uid']
    gid     node['elasticsearch']['user']
    supports :manage_home => false
    action  :create
    system true
  end

  # FIX: Work around the fact that Chef creates the directory even for `manage_home: false`
  bash 'remove the elasticsearch user home' do
    user    'root'
    code    "rm -rf  #{node['elasticsearch']['dir']}/elasticsearch"
    not_if  { ::File.symlink?("#{node['elasticsearch']['dir']}/elasticsearch") }
    only_if { ::File.directory?("#{node['elasticsearch']['dir']}/elasticsearch") }
  end
end


# Create ES directories
#
[ node['elasticsearch']['path']['conf'], node['elasticsearch']['path']['logs'] ].each do |path|
  directory path do
    owner node['elasticsearch']['user'] and group node['elasticsearch']['user'] and mode 0755
    recursive true
    action :create
  end
end

directory node['elasticsearch']['pid_path'] do
  mode '0755'
  recursive true
end

# Create data path directories
#
data_paths = node['elasticsearch']['path']['data'].is_a?(Array) ? node['elasticsearch']['path']['data'] : node['elasticsearch']['path']['data'].split(',')

data_paths.each do |path|
  directory path.strip do
    owner node['elasticsearch']['user'] and group node['elasticsearch']['user'] and mode 0755
    recursive true
    action :create
  end
end

# Create service
#


execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

execute 'set pid file' do
  command "touch #{node['elasticsearch']['pid_file']} && chown #{node['elasticsearch']['user']} #{node['elasticsearch']['pid_file']}"
  not_if {::File.exist?(node['elasticsearch']['pid_file'])}
  action :run
end

if node['elasticsearch']['installation']['mode'] != 'tar'
  case node['platform']
    when 'ubuntu','debian'
      template '/etc/init.d/elasticsearch' do
        source 'elasticsearch.init.erb'
        owner 'root' and mode 0755
      end
  end

else
  template '/etc/init.d/elasticsearch' do
    source 'elasticsearch.init.erb'
    owner 'root' and mode 0755
  end
end
if node['lsb']['codename'] == 'xenial'
  template '/usr/lib/systemd/system/elasticsearch.service' do
    source 'elasticsearch.service.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
  end
  service 'elasticsearch' do
    provider Chef::Provider::Service::Systemd
    retries 5
    retry_delay 10
    supports :status => true, :restart => true
    action [ :enable ]
  end
else
  service 'elasticsearch' do
    supports :status => true, :restart => true
    action [ :enable ]
  end
end

if node['elasticsearch']['installation']['mode'] == 'tar'
  # Download, extract, symlink the elasticsearch libraries and binaries
  #
  ark_prefix_root = node['elasticsearch']['dir'] || node['ark']['prefix_root']
  ark_prefix_home = node['elasticsearch']['dir'] || node['ark']['prefix_home']

  filename = node['elasticsearch']['filename'] || "elasticsearch-#{node['elasticsearch']['version']}.tar.gz"
  download_url = node['elasticsearch']['download_url'] || [node['elasticsearch']['host'],
                node['elasticsearch']['repository'], filename].join('/')

  ark "elasticsearch" do
    url   node['elasticsearch']['download_url']
    owner node['elasticsearch']['user']
    group node['elasticsearch']['user']
    version node['elasticsearch']['version']
    has_binaries ['bin/elasticsearch', 'bin/plugin']
    checksum node['elasticsearch']['checksum']
    prefix_root   ark_prefix_root
    prefix_home   ark_prefix_home

    notifies :start,   'service[elasticsearch]' unless node['elasticsearch']['skip_start']
    notifies :restart, 'service[elasticsearch]' unless node['elasticsearch']['skip_restart']

    not_if do
      link   = "#{node['elasticsearch']['dir']}/elasticsearch"
      target = "#{node['elasticsearch']['dir']}/elasticsearch-#{node['elasticsearch']['version']}"
      binary = "#{target}/bin/elasticsearch"

      ::File.directory?(link) && ::File.symlink?(link) && ::File.readlink(link) == target && ::File.exists?(binary)
    end
  end
end

# Increase open file and memory limits
#
bash "enable user limits" do
  user 'root'

  code <<-END.gsub(/^    /, '')
    echo 'session    required   pam_limits.so' >> /etc/pam.d/su
  END

  not_if { ::File.read("/etc/pam.d/su").match(/^session    required   pam_limits\.so/) }
end

file "/etc/security/limits.d/10-elasticsearch.conf" do
  content <<-END.gsub(/^    /, '')
    #{node['elasticsearch'].fetch('user', "elasticsearch")}     -    nofile    #{node['elasticsearch']['limits']['nofile']}
    #{node['elasticsearch'].fetch('user', "elasticsearch")}     -    memlock   #{node['elasticsearch']['limits']['memlock']}
  END

  notifies :write, 'log[increase limits]', :immediately
end

log "increase limits" do
  message "increased limits for the elasticsearch user"
  action :nothing
end

# Create file with ES environment variables
#
template "elasticsearch-env.sh" do
  path   "#{node['elasticsearch']['path']['conf']}/elasticsearch-env.sh"
  source node['elasticsearch']['templates']['elasticsearch_env']
  owner  node['elasticsearch']['user'] and group node['elasticsearch']['user'] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node['elasticsearch']['skip_restart']
end

# Create ES config file
#
template "elasticsearch.yml" do
  path   "#{node['elasticsearch']['path']['conf']}/elasticsearch.yml"
  source node['elasticsearch']['templates']['elasticsearch_yml']
  owner  node['elasticsearch']['user'] and group node['elasticsearch']['user'] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node['elasticsearch']['skip_restart']
end

# Create ES logging file
#
template "logging.yml" do
  path   "#{node['elasticsearch']['path']['conf']}/logging.yml"
  source node['elasticsearch']['templates']['logging_yml']
  owner  node['elasticsearch']['user'] and group node['elasticsearch']['user'] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node['elasticsearch']['skip_restart']
end
