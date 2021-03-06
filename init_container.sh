#!/bin/bash
cat >/etc/motd <<EOL

________ __________ ____ _____________  _____  .____
\______ \\______    \    |   \______   \/  _  \ |    |
 |    |  \|       _/    |   /|     ___/  /_\  \|    |
 |    \`   \    |   \    |  / |    |  /    |    \    |___
/_______  /____|_  /______/  |____|  \____|__  /_______ \\
        \/       \/                          \/        \/
                         .__
              __________ |  |_______
             /  ___/  _ \|  |\_  __ \\
             \___ (  <_> )  |_|  | \/
            /____  >____/|____/__|
                 \/


       A P P   S E R V I C E   O N   L I N U X

Documentation: http://aka.ms/webapp-linux


EOL
cat /etc/motd


# Get environment variables to show up in SSH session
eval $(printenv | awk -F= '{print "export " $1"="$2 }' >> /etc/profile)


set -ex


# run sshd in background
/usr/sbin/sshd -D &



# PREPARE AND START APACHE

sed -i "s/{WEBSITES_PORT}/${WEBSITES_PORT}/g" /etc/apache2/httpd.conf
sed -i "s/{WEBSITES_HOST}/${WEBSITES_HOST}/g" /etc/apache2/vhost.d/solr-vhost.conf
sed -i "s/{APACHE_REQUIREIP}/${APACHE_REQUIREIP//,/ }/g" /etc/apache2/vhost.d/solr-vhost.conf

htpasswd -b -c /etc/apache2/.htpasswd ${SOLR_USER} ${SOLR_PASSWORD}

mkdir -p /var/lock/apache2
mkdir -p /var/run/apache2

mkdir -p /home/LogFiles
ln -s /home/LogFiles /var/log/apache2

/usr/sbin/httpd -D BACKGROUND &


# PREPARE AND START SOLR

# see https://github.com/wodby/solr/blob/master/entrypoint.sh
init_volumes

if [[ ! -f /opt/solr/server/solr/solr.xml ]]; then
    cp /opt/docker-solr/solr.xml /opt/solr/server/solr/solr.xml
fi

if [[ ! -f /opt/solr/server/solr/configsets ]]; then
    cp -r /opt/docker-solr/configsets /opt/solr/server/solr/configsets
fi

sed -i 's@^SOLR_HEAP=".*"@'"SOLR_HEAP=${SOLR_HEAP}"'@' /opt/solr/bin/solr.in.sh


# move solr data directory to location on /home which is persisted by app service
if [ ! -d "/home/solr/server/solr" ]; then
  mkdir -p /home/solr/server/solr
  cp -rf /opt/solr/server/solr/* /home/solr/server/solr/.
fi
rm -rf /opt/solr/server/solr
ln -s /home/solr/server/solr /opt/solr/server/solr


# execute CMD
exec "$@"
