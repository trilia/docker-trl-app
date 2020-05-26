#FROM jboss/wildfly:10.1.0.Final
#RUN /opt/jboss/wildfly/bin/add-user.sh admin Welcome12# --silent
#CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]


FROM trilia/ubuntu:16.10
MAINTAINER Trilia <trilia.tech@gmail.com>

ARG adminPwd=Welcome12#
ARG clientKey=

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
# RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss

RUN set -ex; \
	\
	groupadd -rf jboss; \
	id -u jboss > /dev/null 2> \&1 || useradd -r -g jboss -d /opt/jboss -m -s /bin/bash jboss;
	

# Creare the necessary directories
RUN set -ex; \
	\
	mkdir -p /trilia/app/lucene; \
	mkdir -p /trilia/app/app-config; \
	chown -R jboss:jboss /trilia; \
	chmod -R 766 /trilia;
	
ADD ./app-config /trilia/app/app-config

RUN	set -ex; \
	\
	cd /trilia/app/app-config; \
	for f in * ; do /usr/bin/dos2unix $f; chown jboss:jboss $f ; chmod 766 $f; done ;
	

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss


# Switch back to jboss user
USER jboss

# Set the JAVA_HOME variable to make it clear where Java is located
#ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 10.1.0.Final

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN set -ex; \
	\
	cd $HOME ; \
	wget -q http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.zip;
	
RUN	set -ex; \
	\
	/bin/busybox unzip wildfly-$WILDFLY_VERSION.zip ; \
	mv $HOME/wildfly-$WILDFLY_VERSION $HOME/wildfly ; \
	rm wildfly-$WILDFLY_VERSION.zip ;

# Set the JBOSS_HOME env variable
ENV JBOSS_HOME /opt/jboss/wildfly

# Add the admin user
RUN $HOME/wildfly/bin/add-user.sh admin ${adminPwd:-Welcome12#}  --silent

#RUN set -ex; \
#	\
#	cd 
#	/usr/bin/dos2unix /trilia/app/app-config/*;

ADD ./keycloak-wildfly-adapter-dist-3.1.0.Final.zip /opt/jboss/wildfly

RUN set -ex; \
	cd /opt/jboss/wildfly; \
	/bin/busybox unzip  keycloak-wildfly-adapter-dist-3.1.0.Final.zip; \
	rm keycloak-wildfly-adapter-dist-3.1.0.Final.zip;
	
RUN set -ex; \
	cd /opt/jboss/wildfly/bin; \
	./jboss-cli.sh --file=adapter-install-offline.cli; 

ADD ./OlpUIFwk2-1.0-SNAPSHOT.war /opt/jboss/wildfly/standalone/deployments

RUN set -ex; \
	/trilia/app/app-config/setup.sh standalone 9bcc6d9f-9c72-4b58-b297-79f0f207d9e1 ;

#VOLUME [/opt/jboss/wildfly/standalone/deployments]

# Expose the ports we're interested in
EXPOSE 8080 9990

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
ENTRYPOINT ["/bin/bash"]
#CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-c", "standalone-full.xml", "-b", "0.0.0.0"]
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "--properties=/trilia/app/app-config/app.properties", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
