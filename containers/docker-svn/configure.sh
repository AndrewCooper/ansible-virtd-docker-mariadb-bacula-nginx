#!/bin/bash
set -e

# Create a directory for webdav conf files
mkdir -p /etc/apache2/sites-available/dav_svn

# Create certificate directories
mkdir -p /etc/grid-security/certificates
mkdir -p /etc/ssl/certs/
mkdir -p /etc/ssl/private

# Create stdout/stderr symlinks to logs
ln -sf /dev/stdout ${APACHE_LOG_DIR}/access.log
ln -sf /dev/stderr ${APACHE_LOG_DIR}/error.log

# enable modules
a2enmod \
  authnz_ldap \
  dav \
  dav_svn \
  ldap \
  ssl

# Enable the site
a2ensite \
  000-default-ssl.conf \
  000-default.conf \
  000-svn.conf \
  000-websvn.conf

rm -f /var/www/html/index.html ${0}
