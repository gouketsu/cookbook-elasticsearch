name             "elasticsearch"

maintainer       "jbdamiano"
maintainer_email "jbdamianno@gmail.com"
license          "Apache"
description      "Installs and configures elasticsearch"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.markdown'))
version          "0.3.9"

depends 'ark', '>= 0.2.4'

recommends 'build-essential', '~> 1.4.4'
recommends 'xml'
recommends 'java'
recommends 'monit'

provides 'elasticsearch'
provides 'elasticsearch::data'
provides 'elasticsearch::ebs'
provides 'elasticsearch::aws'
provides 'elasticsearch::nginx'
provides 'elasticsearch::proxy'
provides 'elasticsearch::plugins'
provides 'elasticsearch::monit'
provides 'elasticsearch::search_discovery'
