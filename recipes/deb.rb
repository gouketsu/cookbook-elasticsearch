# See <http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_linux.html>

filename = node.elasticsearch[:deb_url].split('/').last

remote_file "#{Chef::Config[:file_cache_path]}/#{filename}" do
  source   node.elasticsearch[:deb_url]
  checksum node.elasticsearch[:deb_sha]
  mode 00644
end

dpkg_package "#{Chef::Config[:file_cache_path]}/#{filename}" do
  action :install
  options "--force-yes"
end

#override installation path
node.override[:elasticsearch][:dir]         = '/usr/share/'
node.override[:elasticsearch][:bindir]      = '/usr/share/elasticsearch/bin'
node.override[:elasticsearch][:path][:conf] = '/etc/elasticsearch'
node.override[:elasticsearch][:nginx][:passwords_file] = \
                  "#{node[:elasticsearch][:path][:conf]}/passwords"
