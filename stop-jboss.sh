#!/bin/sh

DIRNAME=`dirname "$0"`
PROGNAME=`basename "$0"`

if [ -r $DIRNAME/setenv.sh ]; then
    . $DIRNAME/setenv.sh
else
    echo "ERROR: $DIRNAME/setenv.sh is not found. please check!"
    exit 1
fi

# Management Port
HOST_MANAGEMENT="localhost"
if [ "x$JBOSS_IP_MANAGEMENT" != "x" ] && [ "$JBOSS_IP_MANAGEMENT" != "0" ]; then
    HOST_MANAGEMENT=$JBOSS_IP_MANAGEMENT
fi 
PORT_MANAGEMENT=$(( ${JBOSS_PORT_OFFSET:-0} + 9990 ))

if [ -x "$JBOSS_CLI" ]; then
    $JBOSS_CLI --controller=$HOST_MANAGEMENT:$PORT_MANAGEMENT --connect command=:shutdown
else
    echo "ERROR: $JBOSS_CLI is not found or executable. please check!"
    exit 1
fi
