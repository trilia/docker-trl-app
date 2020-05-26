#!/bin/bash

export PATH=$PATH:/usr/bin:/usr/local/bin

if [ -z $JBOSS_HOME ]
then
  echo "Jboss home not defined. Exiting !!"
  exit 1
fi

#JBOSS_HOME=/opt/jboss/wildfly
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
JBOSS_MODE=${1:-"standalone"}
CLIENT_KEY=$2

function wait_for_server() {
  until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do
    sleep 1
  done
}


set -ex;

echo "=> Starting WildFly server"; 
#$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -c $JBOSS_CONFIG &
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 & 

echo "=> Waiting for the server to boot"
wait_for_server ;

###$JBOSS_CLI -c "/subsystem=keycloak/secure-deployment=OlpUIFwk2-1.0-SNAPSHOT.war/:add"

#$JBOSS_CLI -c "/subsystem=keycloak/secure-deployment=OlpUIFwk2-1.0-SNAPSHOT.war/:add(realm=bkofc,auth-server-url=http://192.168.99.100:30001/auth, bearer-only=true, ssl-required=EXTERNAL, resource=bkofc-svc, use-resource-role-mappings=false, ssl-required=none, enable-basic-auth=true, client-key-password=${CLIENT_KEY})"

#Workaround for credential not being accepted in above command
#cd ${JBOSS_HOME}/${JBOSS_MODE}/configuration
#sed -i "/<client-key-password/c\<credential name=\"secret\">${CLIENT_KEY}<\/credential>" standalone.xml
  
  
echo "=> Shuting down WildFly ... 1"
if [ "$JBOSS_MODE" = "standalone" ] 
then
  $JBOSS_CLI -c ":shutdown" ;
else
  $JBOSS_CLI -c "/host=*:shutdown";
fi

sleep 10;