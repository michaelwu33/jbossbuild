#!/bin/bash
#
# Build JBOSS
#
#       run as: RUN USER
#       Usage : $APP_HOME/Middleware/scripts/jboss-setup.bash [/path/to/env-jboss.conf]
#         conf: $APP_HOME/Middleware/scripts/env-jboss.conf
#                   JBOSS_PORT_OFFSET=0
#                   JBOSS_IP_MANAGEMENT=0
#                   JBOSS_IP_PUBLIC=0
#                   JVM_XMS=1300m
#                   JVM_XMX=1300m
### TODO                  JVM_METASPACESIZE=96m
### TODO                  JVM_MAXMETASPACESIZE=256m
#                   
#
#       Author: Michael Wu
#
DIRNAME=`dirname "$0"`

if [ -z "$1" ]; then
    ENVFILE=$DIRNAME/env-jboss.conf
else
    ENVFILE=$1
fi
if [ ! -f $ENVFILE ]; then
    echo
    echo "Environment configuration file $ENVFILE doesn't exist. Quiting ..."
    echo
    read -p "Press any key to continue"
    exit 1
fi
echo "Reading settings in configuration file $ENVFILE ... "
source $ENVFILE
# if some important setting is NOT found in env file (e.g. user remove them manually)
if [ -z "$JBOSS_PORT_OFFSET" ]; then
    JBOSS_PORT_OFFSET=0
    echo "JBOSS_PORT_OFFSET=0" >> $ENVFILE
fi
if [ -z "$JBOSS_IP_PUBLIC" ]; then
    JBOSS_IP_PUBLIC=0
    echo "JBOSS_IP_PUBLIC=0" >> $ENVFILE
fi
if [ -z "$JBOSS_IP_MANAGEMENT" ]; then
    JBOSS_IP_MANAGEMENT=0
    echo "JBOSS_IP_MANAGEMENT=0" >> $ENVFILE
fi
if [ -z "$JVM_XMS" ]; then
    JVM_XMS=1300m
    echo "JVM_XMS=1300m" >> $ENVFILE
fi
if [ -z "$JVM_XMX" ]; then
    JVM_XMX=1300m
    echo "JVM_XMX=1300m" >> $ENVFILE
fi

# build script must be run by $RUN_USER
if [ `whoami` != "$RUN_USER" ]; then
	echo
	echo "Run user $RUN_USER is required to setup JBoss instance! quiting..."
	echo
	exit 1
fi

# If we don't see flag file, we are about to change existing setting
FLAGFILE=$DIRNAME/jboss-setup.flag
if [ ! -f $FLAGFILE ]; then
    echo 
    echo "JBoss instance has already been set."
    echo "You are about to modify existing JBoss setting!!!"
    echo
    read -p "Press any key to continue ... "
fi

local new_offset, new_mgmt, new_public, new_xms, new_xmx
while :; do

    new_key=${new_key^^} && [ "$new_key" = "Q" -o "$new_key" = "QUIT" ] && exit 0
    
    clear
    echo 
    echo "JBoss settings :"
    echo    "    Current Port Offset is $JBOSS_PORT_OFFSET"
    read -p "    What's new offset? ($JBOSS_PORT_OFFSET) " new_offset
    echo
    echo    "    Current Public IP is $JBOSS_IP_PUBLIC (0 to bind to any)"
    read -p "    What's new public IP? ($JBOSS_IP_PUBLIC) " new_public
    echo
    echo    "    Current Management is $JBOSS_IP_MANAGEMENT (0 to bind to any)"
    read -p "    What's new management IP? ($JBOSS_IP_MANAGEMENT) " new_mgmt
    echo
    echo "JVM Setting :"
    echo    "    Current JVM minimum heap size is $JVM_XMS"
    read -p "    What's new min size? ($JVM_XMS) " new_xms
    echo
    echo    "    Current JVM maximum heap size is $JVM_XMX"
    read -p "    What's new max size? ($JVM_XMX) " new_xmx
    echo
    echo "Web Console Admin User: "
    read -p  "    Admin User Name: " new_admin
    read -s -p "    Admin User Password: " new_pwd1
    read -s -p "        Repeat Password: " new_pwd2

    # assign to default if no input
    [ -z "$new_offset" ] && new_offset=$JBOSS_PORT_OFFSET
    [ -z "$new_public" ] && new_public=$JBOSS_IP_PUBLIC
    [ -z "$new_mgmt"   ] && new_mgmt=$JBOSS_IP_MANAGEMENT
    [ -z "$new_xms"    ] && new_xms=$JVM_XMS
    [ -z "$new_xmx"    ] && new_xmx=$JVM_XMX
    
    # do basic validation
    if ! [[ $new_offset =~ ^[0-9]+$ ]] || [ "$new_offset" -lt 0 ]; then
        echo
        echo "Offset should be a 0(zero) or a positive integer!"
        echo
        read -p "Press Q to quit, other to re-enter ..." new_key
        continue
    fi
    
    # IP Validation
    # TODO
    [ "$new_public" = "0.0.0.0" ] && new_public=0
    [ "$new_mgmt" = "0.0.0.0"   ] && new_mgmt=0
    # scan up/running IPs
    if [ $new_public -ne 0 ]; then
        #ip -4 -o a | grep $new_public
        :
    fi
    if [ $new_mgmt -ne 0 ]; then
        #ip -4 -o a | grep $new_mgmt
        :
    fi
    
    # JVM: xmx >= xms?
    # TODO
    
    # admin user & pwd
    if [ -z "$new_admin" -o -z "$new_pwd1" -o -z "$new_pwd2" ]; then
        read -p  "Web admin user or password CAN'T be empty! Press any key to re-enter "
        continue
    fi
    if [ "$new_pwd1" != "$new_pwd2" ]; then
        read -p "Password don't match! Press any key to re-enter"
        continue
    fi
    
    # all good
    break

done

#
# to deploy sample app
#
unset new_sample
if [ -f $DIRNAME/sample.war ]; then
    echo
    while :; do
        unset new_key
        read -p "Do you want to deploy bank sample application? Y/N? " new_key
        new_key=${new_key^^} 
        [ "$new_key" = "Y" -o "$new_key" = "YES" -o "$new_key" = "N" -o "$new_key" = "NO" ] && new_sample=$new_key && break
    done
fi

# Write setting to config file
echo
echo "Saving changes ... "
sed -i s/^JBOSS_PORT_OFFSET=$JBOSS_PORT_OFFSET/JBOSS_PORT_OFFSET=$new_offset/g $ENVFILE >/dev/null 2>&1
sed -i s/^JBOSS_IP_MANAGEMENT=$JBOSS_IP_MANAGEMENT/JBOSS_IP_MANAGEMENT=$new_mgmt/g $ENVFILE >/dev/null 2>&1
sed -i s/^JBOSS_IP_PUBLIC=$JBOSS_IP_PUBLIC/JBOSS_IP_PUBLIC=$new_public/g $ENVFILE >/dev/null 2>&1
sed -i s/^JVM_XMS=$JVM_XMS/JVM_XMS=$new_xms/g $ENVFILE >/dev/null 2>&1
sed -i s/^JVM_XMX=$JVM_XMX/JVM_XMX=$new_xmx/g $ENVFILE >/dev/null 2>&1

# deploy sample app
if [ -f $DIRNAME/sample.war ] && [ "$new_sample" = "Y" -o "$new_sample" = "YES" ]; then
    echo "Deploying sample application ..."
    mv $DIRNAME/sample.war $JBOSS_HOME/$JBOSS_MODE/deployments/ >/dev/null 2>&1
    chown $RUN_USER:$GRP_USER $JBOSS_HOME/$JBOSS_MODE/deployments/sample.war >/dev/null 2>&1
fi
mv $DIRNAME/sample.war $APP_HOME/Repositories/ >/dev/null 2>&1

# Web Admin User
echo "Setting Web Admin User ..."
$JBOSS_HOME/bin/add-user.sh $JBOSS_SERVER_BASE_DIR/configuration/ -u $new_admin -p $new_pwd1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Something was wrong when admin user/password was being saved."
    echo "You will have to set this part up seperately later on."
fi

echo
echo
echo "Base on the setting, JBoss instance could be accessed via:"
echo "    - http://<IP-of-Public>:$(($new_offset+8080)) or "
echo "    - https://<IP-of-Public>:$(($new_offset+8443)) "
echo "Web Admin Console: "
echo "    - http://<IP-of-Management>:$(($new_offset+9990)) "
echo
echo Done!

# remove flag file for initial setup
rm -f $FLAGFILE
# End
