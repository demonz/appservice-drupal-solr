#!/bin/bash
cat >/etc/motd <<EOL

   _____  ______________ ________________________
  /  _  \ \____    /    |   \______   \_   _____/
 /  /_\  \  /     /|    |   /|       _/|    __)_
/    |    \/     /_|    |  / |    |   \|        \\
\____|__  /_______ \______/  |____|_  /_______  /
        \/        \/                \/        \/

     A P P   S E R V I C E   O N   L I N U X

Documentation: http://aka.ms/webapp-linux


EOL
cat /etc/motd


# Get environment variables to show up in SSH session
eval $(printenv | awk -F= '{print "export " $1"="$2 }' >> /etc/profile)


# run sshd in background
/usr/sbin/sshd -D &


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
