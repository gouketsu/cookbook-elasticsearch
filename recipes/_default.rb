
if node.elasticsearch[:method] == 'pkg'
  # mandatory path in pkg method (done by packaging)
  # Need to force it in all conditions. So I use the force_override
  node.override[:elasticsearch][:dir]         = '/usr/share/'
  node.override[:elasticsearch][:bindir]      = '/usr/share/elasticsearch/bin'
  node.override[:elasticsearch][:path][:conf] = '/etc/elasticsearch'
  node.override[:elasticsearch][:nginx][:passwords_file] = "#{node.elasticsearch[:path][:conf]}/passwords"
end

