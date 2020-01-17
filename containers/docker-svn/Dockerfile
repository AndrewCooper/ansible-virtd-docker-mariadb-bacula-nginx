#
# SVN Docker container
#
# Version 0.1

FROM php:5.6.40-apache-jessie
LABEL maintainer="Andrew Cooper <andrew.cooper@novatechweb.com>"

# install the required packages and cleanup the install
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    # apache2 \
    # ca-certificates \
    enscript \
    libapache2-mod-svn \
    # php5-common \
    subversion \
    # websvn \
    && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ARG WEBSVN_URL="https://github.com/websvnphp/websvn/archive/2.3.3.tar.gz"
ARG WEBSVN_SHA256="bde955327bf83555b33a2e3bd2ca3dfb514fd87eb814bda79101f9f19e48d080"
RUN curl -L -o "/tmp/websvn.tar.gz" "${WEBSVN_URL}" \
&&  echo "${WEBSVN_SHA256} /tmp/websvn.tar.gz" > /tmp/websvn.sha256 \
&&  sha256sum -c /tmp/websvn.sha256 \
&&  mkdir -p /opt/websvn \
&&  tar -v -x -C /opt/websvn --strip-components=1 -f /tmp/websvn.tar.gz \
&&  rm -vf "/tmp/websvn.tar.gz"

# copy over files
COPY \
  config/000-default-ssl.conf \
  config/000-default.conf \
  config/000-svn.conf \
  config/000-websvn.conf \
    /etc/apache2/sites-available/
COPY config/ldap.conf /etc/apache2/mods-available/
COPY config/config.php /opt/websvn/include/
COPY ./docker-entrypoint.sh ./configure.sh /

ENV APACHE_DOCUMENT_ROOT="/var/www/html/" \
    APACHE_LOG_DIR="/tmp" \
    LDAP_URL="ldap://ldap/ou=user,dc=novatech?uid?sub?(objectClass=Person)" \
    LDAP_BIND_DN="cn=proxyagent,dc=novatech" \
    LDAP_BIND_PW="novatech" \
    LDAP_GROUP_DN="cn=%{SERVER_NAME},ou=group,dc=novatech" \
    SVN_BASE_DIR="/var/lib/svn" \
    SVN_HOSTNAME="svn.example.com"

# run the configuration script
RUN ["/bin/bash", "/configure.sh"]

# specify which network ports will be used
EXPOSE 80 443

# specify the volumes directly related to this image
VOLUME ["/var/lib/svn"]

# start the entrypoint script
WORKDIR /var/lib/svn
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["svn"]
