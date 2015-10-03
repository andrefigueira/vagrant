#!/bin/bash
# Using Trusty64 Ubuntu

#
# Add Phalcon repository
#
sudo apt-add-repository -y ppa:phalcon/stable
sudo apt-get update

#
# MySQL with root:<no password>
#
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install mysql-server

#
# PHP
#
sudo apt-get install -y php5 php5-dev apache2 libapache2-mod-php5 libpcre3-dev
sudo apt-get install -y php5-mcrypt php5-curl php5-intl php5-mysql

#
# Redis
#
sudo apt-get install -y redis-server

#
# MongoDB
#
sudo apt-get install -y mongodb-clients mongodb-server

#
# Utilities
#
sudo apt-get install -y curl htop git-core vim

#
# Redis Configuration
# Allow us to Remote from Vagrant with Port
#
sudo cp /etc/redis/redis.conf /etc/redis/redis.bkup.conf
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo /etc/init.d/redis-server restart

#
# MySQL Configuration
# Allow us to Remote from Vagrant with Port
#
sudo cp /etc/mysql/my.cnf /etc/mysql/my.bkup.cnf
# Note: Since the MySQL bind-address has a tab cahracter I comment out the end line
sudo sed -i 's/bind-address/bind-address = 0.0.0.0#/' /etc/mysql/my.cnf

#
# Grant All Priveleges to ROOT for remote access
#
mysql -u root -Bse "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
sudo service mysql restart

#
# Composer for PHP
#
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

#
# Apache VHost
#
cd ~
echo '<VirtualHost *:80>
        DocumentRoot /vagrant/www
        ServerName phalcon.local
</VirtualHost>

<Directory "/vagrant/www">
        Options Indexes Followsymlinks
        AllowOverride All
        Require all granted
</Directory>' > vagrant.conf

sudo mv vagrant.conf /etc/apache2/sites-available

#
# Custom VHost
#

cd ~
echo '<VirtualHost *:80>
        DocumentRoot /vagrant/www/designfront.co.uk-new/public
        ServerName designfront.local
</VirtualHost>

<Directory "/vagrant/www/designfront.co.uk-new">
        Options Indexes Followsymlinks
        AllowOverride All
        Require all granted
</Directory>' > designfront.conf

sudo mv designfront.conf /etc/apache2/sites-available

sudo a2enmod rewrite

#
# Install PhalconPHP
#
sudo apt-get install -y php5-phalcon

#
# Install PhalconPHP DevTools
#
cd ~
echo '{"require": {"phalcon/devtools": "dev-master"}}' > composer.json
composer install
rm composer.json

sudo mkdir /opt/phalcon-tools
sudo mv ~/vendor/phalcon/devtools/* /opt/phalcon-tools
sudo ln -s /opt/phalcon-tools/phalcon.php /usr/bin/phalcon
sudo rm -rf ~/vendor

#
# Enable PHP5 Mods
#
sudo php5enmod phalcon curl mcrypt intl

# Install Yaml

echo "Installing YAML extension"
sudo apt-get install libyaml-dev
sudo pecl install yaml-beta

sudo echo "extension=yaml.so" >> /etc/php5/apache2/php.ini


#
# Update PHP Error Reporting
#
sudo sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php5/apache2/php.ini
sudo sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/' /etc/php5/apache2/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php5/apache2/php.ini
#  Append session save location to /tmp to prevent errors in an odd situation..
sudo sed -i '/\[Session\]/a session.save_path = "/tmp"' /etc/php5/apache2/php.ini

#
# Reload apache
#
sudo a2ensite vagrant
sudo a2ensite designfront
sudo a2dissite 000-default
sudo service apache2 restart
sudo service mongodb restart

#
#  Cleanup
#
sudo apt-get autoremove -y

echo -e "----------------------------------------"
echo -e "To create a Phalcon Project:\n"
echo -e "----------------------------------------"
echo -e "$ cd /vagrant/www"
echo -e "$ phalcon project projectname\n"
echo -e
echo -e "Then follow the README.md to copy/paste the VirtualHost!\n"

echo -e "----------------------------------------"
echo -e "Default Site: http://192.168.50.4"
echo -e "----------------------------------------"
