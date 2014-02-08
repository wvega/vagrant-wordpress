#!/usr/bin/env bash

INSTALL_DIR=/vagrant/wordpress
DOCUMENT_ROOT=/var/www/html/wordpress

HOME_URL=example.com
BLOG_NAME="Example Blog"
ADMIN_EMAIL=admin@$HOME_URL

# TODO: Maybe disable mirros in YUM repos, use baseurl. Sometimes there are a lot of
# network problems with local mirrors.
yum install -y httpd mysql mysql-server php php-mysql php-gd php-pecl-imagick
yum install -y php-phpunit-PHPUnit php-digitalsandwich-Phake php-pecl-xdebug
yum install -y rsync git svn wget autojump
yum install -y system-config-firewall-tui
yum install -y perl-Digest-SHA

# install WP-CLI
if [ ! -f /usr/bin/wp ]; then
    wget --quiet https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod a+x wp-cli.phar
    mv wp-cli.phar /usr/bin/wp
fi

# Configure PHP
sed -i s/'display_errors = Off'/'display_errors = On'/ /etc/php.ini
sed -i s/'html_errors = Off'/'html_errors = On'/ /etc/php.ini
sed -i s/'upload_max_filesize = 2M'/'upload_max_filesize = 10M'/ /etc/php.ini

# Configure MySQL
systemctl enable mysqld.service
systemctl start mysqld.service

mysqladmin -uroot password password || true
mysqladmin create wordpress -uroot -ppassword || true
mysql -uroot -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;"

# Configure Apache
systemctl enable httpd.service
sed -i s/'#ServerName www.example.com:80'/'ServerName localhost:80'/ /etc/httpd/conf/httpd.conf

# Configure WordPress VirtualHost
mkdir -p $DOCUMENT_ROOT

cat <<VHOST > /etc/httpd/conf.d/wordpress.conf
<VirtualHost *:80>
  ServerName $HOME_URL
  DocumentRoot $DOCUMENT_ROOT

  <Directory $DOCUMENT_ROOT>
    Options FollowSymLinks
    AllowOverride FileInfo Options
    Order allow,deny
    Allow from all
  </Directory>

  <Directory />
    Options FollowSymLinks
    AllowOverride None
  </Directory>

  LogLevel info
  ErrorLog /var/log/httpd/wordpress-error.log
  CustomLog /var/log/httpd/wordpress-access.log combined

  RewriteEngine On
</VirtualHost>
VHOST

cat <<HTACCESS > $DOCUMENT_ROOT/.htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
HTACCESS

chown vagrant:vagrant $DOCUMENT_ROOT/.htaccess
chmod 0644 $DOCUMENT_ROOT/.htaccess

# Install WordPress
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

if [ ! -f wp-settings.php ]; then
    su vagrant -c 'wp core download'
fi

if [ ! -f wp-config.php ]; then
    su vagrant -c "wp core config --dbname=wordpress --dbuser=root --dbpass=password --extra-php <<PHP
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
PHP"
fi

if ! su vagrant -c "wp core is-installed"; then
    su vagrant -c "wp core install --title='$BLOG_NAME' --admin_email=wvega@wvega.com --admin_user=admin --admin_password=password --url='$HOME_URL/wp-admin/install.php'"
fi

if ! (su vagrant -c "wp user list --fields=user_email" | grep john@$HOME_URL); then
    su vagrant -c "wp user create john john@$HOME_URL --user_pass=password --display_name='John Doe'"
fi

if ! (su vagrant -c "wp user list --fields=user_email" | grep jane@$HOME_URL); then
    su vagrant -c "wp user create jane jane@$HOME_URL --user_pass=password --display_name='Jane Doe'"
fi

mkdir -p $INSTALL_DIR/wp-content/{uploads,upgrade,plugins}

chown vagrant:vagrant $INSTALL_DIR/wp-content/uploads
chmod -R 0777 $INSTALL_DIR/wp-content/uploads

chown vagrant:vagrant $INSTALL_DIR/wp-content/upgrade
chmod -R 0777 $INSTALL_DIR/wp-content/upgrade

chown vagrant:vagrant $INSTALL_DIR/wp-content/plugins
chmod -R 0777 $INSTALL_DIR/wp-content/plugins

# Install WordPress testing framework
export WP_TESTS_DIR=$INSTALL_DIR/tests

if ! mysqlshow tests -uroot -ppassword; then
    su vagrant -c "wp scaffold plugin-tests akismet"

    mv wp-content/plugins/akismet/bin/install-wp-tests.sh /vagrant/scripts/
    mv wp-content/plugins/akismet/.travis.yml /vagrant/.travis.yml.new

    su vagrant -c "bash /vagrant/scripts/install-wp-tests.sh tests root password localhost latest"
fi

if [ -f $WP_TESTS_DIR/wp-tests-config.php ]; then
    sed -i s/'\/tmp\/wordpress'/'\/vagrant\/wordpress'/ $WP_TESTS_DIR/wp-tests-config.php
    sed -i s/'Test Blog'/'$BLOG_NAME'/ $WP_TESTS_DIR/wp-tests-config.php
    sed -i s/admin@example.org/$ADMIN_EMAIL/ $WP_TESTS_DIR/wp-tests-config.php
    sed -i s/example.org/$HOME_URL/ $WP_TESTS_DIR/wp-tests-config.php
fi

# Install script to sync plugin files on guest server
DEST=`dirname $DOCUMENT_ROOT`

cat <<EOF > /usr/local/bin/sync-plugin-files
#!/bin/bash
sudo rsync -avtk $INSTALL_DIR $DEST --exclude=tests --exclude=wp-content/uploads
EOF

chown vagrant:vagrant /usr/local/bin/sync-plugin-files
chmod 0755 /usr/local/bin/sync-plugin-files

# Configure firewall
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https
firewall-cmd --zone=public --add-service=mysql

# Add environment variables
if ! grep WP_TESTS_DIR /home/vagrant/.bash_profile; then
cat <<EOF >> /home/vagrant/.bash_profile

export WP_TESTS_DIR=$INSTALL_DIR/tests/
EOF
fi

# Restart services
systemctl restart httpd.service
systemctl restart mysqld.service
