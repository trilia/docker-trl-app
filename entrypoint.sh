#!/bin/bash

export PATH=$PATH:/usr/bin:/usr/local/bin

echo "All args - $* "

ACTIVE_USER_ID=1011
ACTIVE_USER_NAME=jboss
ACTIVE_GROUP_ID=1011
ACTIVE_GROUP_NAME=jboss

CREATE_USER=0
CREATE_GROUP=0

echo $HOST_USER_ID
echo $HOST_USER_NAME
echo $HOST_GROUP_ID
echo $HOST_GROUP_NAME


if [ -z $HOST_USER_ID ]
then
  echo "No host user id passed as env. Will default to $ACTIVE_USER_ID "
else
        if  [[ ($HOST_USER_ID -ge 0) && ($HOST_USER_ID -le 100) ]]
  then
    echo "Privileged user id has been passed as env. Downgrading and defaulting to $ACTIVE_USER_ID"
  else
    echo "Non-privileged user id $HOST_USER_ID has been used by host"
    ACTIVE_USER_ID=$HOST_USER_ID
  fi
fi

if [ -z $HOST_USER_NAME ]
then
  echo "No host user name passed as env. Will default to $ACTIVE_USER_NAME "
else
  echo "Non-privileged user name $HOST_USER_NAME has been used by host"
  ACTIVE_USER_NAME=$HOST_USER_NAME
fi

user_id_if_exists=`id -nu $ACTIVE_USER_ID >/dev/null 2>&1`
result=$?
if [ $result -ne 0 ]
then
  echo "User id $ACTIVE_USER_ID does not exist and will be created"
  CREATE_USER=1
fi

user_name_if_exists=`id -u $ACTIVE_USER_NAME > /dev/null 2>&1`
result=$?
if [ $result -ne 0 ]
then
  if [ $CREATE_USER -eq 1 ]
  then
    echo "User $ACTIVE_USER_NAME does not exist and will be created"
  else
    echo "User id $ACTIVE_USER_ID does not exist, however $ACTIVE_USER_NAME exists. Could not resolve conflict, exiting !"
        exit 1
  fi
fi

if [ -z $HOST_GROUP_ID ]
then
  echo "No host group id passed as env. Will default to $ACTIVE_GROUP_ID"
else
  if [[ ($HOST_GROUP_ID -ge 0) && ($HOST_GROUP_ID -le 100) ]]
  then
    echo "Privileged group id has been passed as env. Downgrading and defaulting to $ACTIVE_GROUP_ID"
  else
    echo "Non-privileged group id $HOST_GROUP_ID has been used by host"
    ACTIVE_GROUP_ID=$HOST_GROUP_ID
  fi
fi

if [ -z $HOST_GROUP_NAME ]
then
  echo "No host group name passed as env. Will default to $ACTIVE_GROUP_NAME "
else
  echo "Non-privileged group name $HOST_GROUP_NAME has been used by host"
  ACTIVE_GROUP_NAME=$HOST_GROUP_NAME
fi

group_id_if_exists=`getent group $ACTIVE_GROUP_ID >/dev/null 2>&1`
result=$?
if [ $result -ne 0 ]
then
  echo "Group id $ACTIVE_GROUP_ID does not exist and will be created"
  CREATE_GROUP=1
fi

group_name_if_exists=`getent group $ACTIVE_GROUP_NAME >/dev/null 2>&1`
result=$?
if [ $result -ne 0 ]
then
  if [ $CREATE_GROUP -eq 1 ]
  then
    echo "Group $ACTIVE_GROUP_NAME does not exist and will be created"
  else
    echo "Group id $ACTIVE_GROUP_ID does not exist, however $ACTIVE_GROUP_NAME exists. Could not resolve conflict, exiting !"
        exit 1
  fi
fi


if [ $CREATE_USER -eq 1 ]
then
  echo "User creation in progress ... "
  if [ $CREATE_GROUP -eq 1 ]
  then
    echo "Attempting to create group $ACTIVE_GROUP_NAME ..."
    groupadd -rf -g $ACTIVE_GROUP_ID $ACTIVE_GROUP_NAME
    echo "Done creating group"
  fi
  echo "Attempting to create user $ACTIVE_USER_NAME ..."
    useradd -r -u $ACTIVE_USER_ID -g $ACTIVE_GROUP_NAME -d /home/$ACTIVE_USER_NAME -m -s /bin/bash $ACTIVE_USER_NAME
  echo "Done creating user"
fi

#JBOSS_HOME="$1"
if [ -z $JBOSS_HOME ]
then
  echo "Jboss home not passed as argument"
  exit 1
else
  echo "Jboss home - $JBOSS_HOME "
fi

chown -R $ACTIVE_USER_NAME:$ACTIVE_GROUP_NAME /wildfly
chown -R $ACTIVE_USER_NAME:$ACTIVE_GROUP_NAME /trilia

adminPwd="$ADMIN_PWD"
#echo "Admin pwd - ${adminPwd:-trilia}"

$JBOSS_HOME/bin/add-user.sh admin ${adminPwd:-Welcome12#}  --silent

#Copy the existing config files

cd $JBOSS_HOME/standalone/configuration 

/usr/local/bin/gosu $ACTIVE_USER_NAME mv standalone-ha.xml  standalone-ha.xml.org
/usr/local/bin/gosu $ACTIVE_USER_NAME mv standalone-full-ha.xml  standalone-full-ha.xml.org

cd

echo "Copying configuration artifacts ..."

/usr/local/bin/gosu $ACTIVE_USER_NAME cp /wildfly/artifacts/standalone-ha.xml $JBOSS_HOME/standalone/configuration/
/usr/local/bin/gosu $ACTIVE_USER_NAME cp /wildfly/artifacts/standalone-full-ha.xml $JBOSS_HOME/standalone/configuration/

/usr/local/bin/gosu $ACTIVE_USER_NAME cp /wildfly/artifacts/OlpUIFwk2-1.0-SNAPSHOT.war $JBOSS_HOME/standalone/deployments/

echo "End copying artifacts"

echo "Performing setup ..."

/usr/local/bin/gosu $ACTIVE_USER_NAME /trilia/svc/svc-config/setup.sh standalone 9bcc6d9f-9c72-4b58-b297-79f0f207d9e1

echo "Done with setup"

echo "Starting Jboss server..."

/usr/local/bin/gosu $ACTIVE_USER_NAME $JBOSS_HOME/bin/standalone.sh --properties="/trilia/svc/svc-config/app.properties" -b "0.0.0.0" "-bmanagement" "0.0.0.0" "${@:2}"

#/bin/bash


