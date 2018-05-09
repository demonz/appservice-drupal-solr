FROM nbcwebcontainers.azurecr.io/wodby-drupal-solr:7-5.5

MAINTAINER Demonz Media <hello@demonzmedia.com>


RUN apk add --update --no-cache --virtual .solr-rundeps \
  openssh-server vim wget


COPY sshd_config /etc/ssh/
COPY init_container.sh /bin/


RUN echo "root:Docker!" | chpasswd \
  && chmod 777 /var/log \
  && chmod 777 /var/run \
  && chmod 777 /var/lock \
  && chmod 755 /bin/init_container.sh


EXPOSE 2222 8983

ENTRYPOINT ["/bin/init_container.sh"]
CMD ["docker-entrypoint.sh", "solr-foreground"]
