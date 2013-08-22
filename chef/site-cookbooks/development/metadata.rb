name             'development'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures WordPres for Plugins/Themes Development'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "iptables"
depends "database"
depends "mysql"
depends "wordpress"

depends "phpunit"
depends "selenium"
depends "wp-cli"
