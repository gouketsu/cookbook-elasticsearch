include_recipe "elasticsearch::_default"
# This recipe configures the cluster to use Chef search for discovering Elasticsearch nodes.
# This allows the cluster to operate without multicast, without AWS, and without having to manually manage nodes.
#
# By default it will search for other nodes with the query
# `role:elasticsearch AND chef_environment:#{node.chef_environment} AND elasticsearch_cluster_name:#{node[:elasticsearch][:cluster][:name]}`, but you may override that with the
# `node['elasticsearch']['discovery']['search_query']` attribute.
#
# Reasonable values include
# `"tag:elasticsearch AND chef_environment:#{node.chef_environment}"` and
# `"(role:es-server OR role:es-client) AND chef_environment:#{node.chef_environment}"`.
#
# By default it will attempt to select a reasonable IP address for each
# node, using `node['cloud']['local_ipv4']` on cloud servers, and
# `node['ipaddress']` elsewhere.
#
# You may override that with the
# `node'elasticsearch']['discovery']['node_attribute']` attribute.
# Reasonable values include `"fqdn"` and `"cloud.public_ipv4`.
#
node.set['elasticsearch']['discovery']['zen']['ping']['multicast']['enabled'] = false
nodes = search_for_nodes(node['elasticsearch']['discovery']['search_query'],
                         node['elasticsearch']['discovery']['node_attribute'])


Chef::Log.debug("Found elasticsearch nodes at #{nodes.join(', ').inspect}")

#add local ip address in case of it is not found. First time start
if node['elasticsearch']['discovery']['node_attribute'].nil?
   nodes << "#{node.ipaddress}" unless nodes.include?("#{node.ipaddress}")
else
   keys = node['elasticsearch']['discovery']['node_attribute'].split('.')
   value = node
   keys.each do |key|
      value = value[key]
   end
   nodes << "#{value}" unless nodes.include?("#{value}")
end

node.set['elasticsearch']['discovery']['zen']['ping']['unicast']['hosts'] = nodes.join(',')

# set minimum_master_nodes to n/2+1 to avoid split brain scenarios
limit=(nodes.length / 2).floor
limit += 1 unless nodes.length == 2
node.default['elasticsearch']['discovery']['zen']['minimum_master_nodes'] = limit

# we don't want all of the nodes in the cluster to restart when a new node joins
node.set['elasticsearch']['skip_restart'] = true
