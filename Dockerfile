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
#COPY entrypoint.sh /

#USER $SOLR_USER

#VOLUME /opt/solr/server/solr
#WORKDIR /opt/solr/server/solr

#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["solr-foreground"]



# Modified from https://github.com/wodby/drupal-solr/blob/master/Dockerfile
#ARG BASE_IMAGE_TAG
#FROM wodby/solr:${BASE_IMAGE_TAG}

# SEARCH_API_SOLR_VER=7.x-1.12
ARG SEARCH_API_SOLR_VER
ENV SEARCH_API_SOLR_VER="${SEARCH_API_SOLR_VER}"

#USER root

RUN set -ex; \
    \
    # Downloading config set from search_api_solr drupal module
    url="https://ftp.drupal.org/files/projects/search_api_solr-${SEARCH_API_SOLR_VER}.tar.gz"; \
    wget -qO- "${url}" | tar xz -C /opt/docker-solr/scripts/; \
    mkdir -p /opt/docker-solr/configsets/drupal; \
    mv "/opt/docker-solr/scripts/search_api_solr/solr-conf/${SOLR_VER:0:1}.x" /opt/docker-solr/configsets/drupal/conf; \
    rm -rf /opt/docker-solr/scripts/search_api_solr; \
    chown -R $SOLR_USER:$SOLR_USER /opt/docker-solr/configsets/drupal/; \
    \
    # Change default config set to drupal
    sed -i -e 's/data_driven_schema_configs/drupal/g' /usr/local/bin/actions.mk; \
    sed -i -e 's/_default/drupal/g' /usr/local/bin/actions.mk;

#USER $SOLR_USER



# CUSTOM
# Add ssh server for access via Azure portal
# Customise init_container.sh to start sshd and
# move solr work directory to file system persisted by App Service

MAINTAINER Demonz Media <hello@demonzmedia.com>


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



COPY init_container.sh /bin/
COPY sshd_config /etc/ssh/


RUN set -ex; \
    \
    chmod 755 /bin/init_container.sh


WORKDIR /home

EXPOSE 2222 8983

ENTRYPOINT ["/bin/init_container.sh"]
CMD ["docker-entrypoint.sh", "solr-foreground"]
