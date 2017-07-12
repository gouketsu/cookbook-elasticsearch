name             "elasticsearch"

maintainer       "Jean-Bernard Damiano"
maintainer_email "jbdamiano@gmail.com"
license          "Apache"
description      "Installs and configures elasticsearch"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.markdown'))
version          "5.2.2"

depends 'ark', '>= 0.2.4'

suggests 'build-essential'
suggests 'xml'
suggests 'java'
suggests 'monit'

provides 'elasticsearch'
provides 'elasticsearch::data'
provides 'elasticsearch::ebs'
provides 'elasticsearch::aws'
provides 'elasticsearch::gce'
provides 'elasticsearch::nginx'
provides 'elasticsearch::proxy'
provides 'elasticsearch::plugins'
provides 'elasticsearch::monit'
provides 'elasticsearch::search_discovery'
