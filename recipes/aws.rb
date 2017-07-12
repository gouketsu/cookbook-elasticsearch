default['elasticsearch']['plugin']['mandatory'] = Array(node['elasticsearch']['plugin']['mandatory'] | ['cloud-aws'])
node.normal['elasticsearch']['cloud']['node']['auto_attributes'] = true
install_plugin "elasticsearch/elasticsearch-cloud-aws/#{node['elasticsearch']['plugins']['elasticsearch/elasticsearch-cloud-aws']['version']}"
