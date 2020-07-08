MAINTAINER Trilia <trilia.tech@gmail.com>

ARG adminPwd=Welcome12#
ARG clientKey=

RUN set -ex; \
        \
        apt update -y && apt install -y unzip;

RUN set -ex; \
        \
        mkdir -p /wildfly/artifacts; \
        chmod -R 766 /wildfly;

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 19.1.0.Final

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN set -ex; \
        \
        cd /tmp ; \
        wget -q http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.zip; \
        ls -l /tmp/wild*;

RUN set -ex; \
        \
        cd /tmp; \
        unzip -q wildfly-$WILDFLY_VERSION.zip -d /wildfly; \
        rm wildfly-$WILDFLY_VERSION.zip;

ENV JBOSS_HOME /wildfly/wildfly-$WILDFLY_VERSION

#RUN set -ex; \
#       \
#       export $JBOSS_HOME;

# Add the admin user
RUN $JBOSS_HOME/bin/add-user.sh admin ${adminPwd:-Welcome12#}  --silent

RUN set -ex; \
        \
        mkdir -p /scripts/config; \
        mkdir -p /trilia/wildfly/log; \
        mkdir -p /trilia/templates/svc-config; \
        mkdir -p /trilia/svc/svc-config; \
        mkdir -p /trilia/svc/lucene1/indexes; \
        mkdir -p /trilia/svc/lucene2/indexes;

ADD ./entrypoint.sh /scripts/config
ADD ./standalone-ha.xml /wildfly/artifacts
ADD ./standalone-full-ha.xml /wildfly/artifacts
#ADD ./module.xml /wildfly/artifacts
#ADD ./jgroups-kubernetes-1.0.16.Final.jar /wildfly/artifacts
ADD ./svc-config /trilia/templates/svc-config

ADD ./TriliaMain-1.0-SNAPSHOT.war /wildfly/artifacts

RUN     set -ex; \
        \
        cd /trilia/templates/svc-config; \
        for f in * ; do /usr/bin/dos2unix $f; chmod 766 $f; done ;


RUN set -ex; \
        \
        /usr/bin/dos2unix /scripts/config/entrypoint.sh; \
        /usr/bin/dos2unix /wildfly/artifacts/standalone-ha.xml; \
        /usr/bin/dos2unix /wildfly/artifacts/standalone-full-ha.xml;
#        /usr/bin/dos2unix /wildfly/artifacts/module.xml;

RUN set -ex; \
    chmod 754 /scripts/config/entrypoint.sh;

VOLUME [ "/trilia/wildfly/log", "/trilia/svc/lucene1/indexes", "/trilia/svc/lucene2/indexes" ]

EXPOSE 8080 9990


ENTRYPOINT [ "/scripts/config/entrypoint.sh", "/wildfly/wildfly-19.1.0.Final" ]

#CMD ["/opt/jboss/wildfly/bin/standalone.sh", "--properties=/trilia/app/app-config/app.properties", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
CMD [ "-c", "standalone-ha.xml" ]
