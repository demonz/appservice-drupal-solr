# Modified from https://github.com/wodby/solr/blob/master/Dockerfile
# SOLR_VER=5.5
ARG SOLR_VER

FROM solr:${SOLR_VER}-alpine

ARG SOLR_VER

ENV SOLR_HEAP="1024m" \
    SOLR_VER="${SOLR_VER}"

USER root

RUN set -ex; \
    \
    apk add --no-cache \
        curl \
        make \
        sudo; \
    \
    # Script to fix volumes permissions via sudo.
    echo "chown solr:solr /opt/solr/server/solr" > /usr/local/bin/init_volumes; \
    chmod +x /usr/local/bin/init_volumes; \
    echo 'solr ALL=(root) NOPASSWD:SETENV: /usr/local/bin/init_volumes' > /etc/sudoers.d/solr; \
    \
    # Move out from volume for persistency
    mv /opt/solr/server/solr/solr.xml /opt/docker-solr/solr.xml; \
    mv /opt/solr/server/solr/configsets /opt/docker-solr/configsets;

COPY actions /usr/local/bin


# Modified from https://github.com/wodby/drupal-solr/blob/master/Dockerfile
# SEARCH_API_SOLR_VER=7.x-1.12
ARG SEARCH_API_SOLR_VER
ENV SEARCH_API_SOLR_VER="${SEARCH_API_SOLR_VER}"

RUN set -ex; \
    \
    # Downloading config set from search_api_solr drupal module
    url="https://ftp.drupal.org/files/projects/search_api_solr-${SEARCH_API_SOLR_VER}.tar.gz"; \
    wget -qO- "${url}" | tar xz -C /opt/docker-solr/scripts/; \
    mkdir -p /opt/docker-solr/configsets/drupal; \
    mv "/opt/docker-solr/scripts/search_api_solr/solr-conf/${SOLR_VER:0:1}.x" /opt/docker-solr/configsets/drupal/conf; \
    \
    # change lock type to allow multiple solr instances to use the same index
    sed -i "s/solr.lock.type:native/solr.lock.type:simple/" /opt/docker-solr/configsets/drupal/conf/solrconfig.xml; \
    \
    rm -rf /opt/docker-solr/scripts/search_api_solr; \
    chown -R $SOLR_USER:$SOLR_USER /opt/docker-solr/configsets/drupal/; \
    \
    # Change default config set to drupal
    sed -i -e 's/data_driven_schema_configs/drupal/g' /usr/local/bin/actions.mk; \
    sed -i -e 's/_default/drupal/g' /usr/local/bin/actions.mk;


# CUSTOM
# Add ssh server for access via Azure portal
# Customise init_container.sh to start sshd and
# move solr work directory to file system persisted by App Service
MAINTAINER Demonz Media <hello@demonzmedia.com>

# install and prepare sshd
# change root password to allow login via azure portal
RUN set -ex; \
    \
    apk add --no-cache \
      openssh-server vim; \
    \
    # generate keys
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa; \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa; \
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa; \
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519; \
    \
    # prepare run dir
    mkdir -p /var/run/sshd; \
    \
    echo "root:Docker!" | chpasswd


# install apache with proxy module to provide security to solr
# https://github.com/seibert-media/docker-alpine-apache-proxy/blob/master/Dockerfile
RUN set -ex; \
    \
    apk add --no-cache \
      apache2 apache2-proxy apache2-utils; \
    sed -i 's/^LoadModule proxy_fdpass_module/#LoadModule proxy_fdpass_module/' /etc/apache2/conf.d/proxy.conf; \
    sed -i "s/^#LoadModule slotmem_shm_module/LoadModule slotmem_shm_module/" /etc/apache2/httpd.conf; \
    sed -i "s/^#LoadModule rewrite_module/LoadModule rewrite_module/" /etc/apache2/httpd.conf; \
    sed -i "s/^ServerTokens OS/ServerTokens Prod/" /etc/apache2/httpd.conf; \
    sed -i "s/^ServerSignature On/ServerSignature Off/" /etc/apache2/httpd.conf; \
    sed -i "s/^#ServerName www.example.com:80/ServerName localhost/" /etc/apache2/httpd.conf; \
    echo "IncludeOptional /etc/apache2/vhost.d/*.conf" >> /etc/apache2/httpd.conf; \
    mkdir -p /run/apache2 /etc/apache2/vhost.d; \
    ln -sf /proc/self/fd/1 /var/log/apache2/access.log; \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log;


COPY init_container.sh /bin/
COPY solr-vhost.conf /etc/apache2/vhost.d/
COPY sshd_config /etc/ssh/


RUN set -ex; \
   rm -f /var/log/apache2/*; \
   rmdir /var/log/apache2; \
   chmod 777 /var/log; \
   chmod 777 /var/run; \
   chmod 777 /var/lock; \
   chmod 755 /bin/init_container.sh;


WORKDIR /home

EXPOSE 2222 80

ENTRYPOINT ["/bin/init_container.sh"]
CMD ["docker-entrypoint.sh", "solr-foreground"]
