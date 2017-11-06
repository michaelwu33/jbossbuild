#!/bin/sh

DIRNAME=`dirname "$0"`
if [ ! -r $DIRNAME/env-jboss.conf ]; then
    echo
    echo "Can NOT read environment file $DIRNAME/env-jboss.conf, please check ... "
    echo
    exit
fi
source $DIRNAME/env-jboss.conf

[ -z "$APP_HOME"   ] && APP_HOME=`cd "$DIRNAME/../.." >/dev/null; pwd`
[ -z "$JBOSS_USER" ] && JBOSS_USER=`whoami`
[ -z "$JAVA_HOME"  ] && JAVA_HOME=$APP_HOME/Middleware/JAVA
[ -z "$JBOSS_HOME" ] && JBOSS_HOME=$APP_HOME/Middleware/MiddlewareApp
JBOSS_CONSOLE_LOG=$JBOSS_HOME/standalone/log/console.log
JBOSS_PIDFILE=$JBOSS_HOME/standalone/tmp/jboss-eap.pid
JBOSS_LOCKFILE=$JBOSS_HOME/standalone/tmp/jboss-eap.lock
JBOSS_MARKERFILE=$JBOSS_HOME/standalone/tmp/startup-marker

export LAUNCH_JBOSS_IN_BACKGROUND=1
export APP_HOME JBOSS_HOME JAVA_HOME JBOSS_USER

##
## Additionals args to include in startup
##
if [ "x$JBOSS_OPTS" = "x" ]; then
    # base directory. by running mode
    JBOSS_OPTS="-Djboss.server.base.dir=$JBOSS_HOME/$JBOSS_MODE"
    # JBOSS_PORT_OFFSET
    JBOSS_OPTS="$JBOSS_OPTS -Djboss.socket.binding.port-offset=${JBOSS_PORT_OFFSET:-0}"
    # JBOSS_IP_MANAGEMENT
    JBOSS_OPTS="$JBOSS_OPTS -Djboss.bind.address.management=${JBOSS_IP_MANAGEMENT:-0}"
    # JBOSS_IP_PUBLIC
    JBOSS_OPTS="$JBOSS_OPTS -Djboss.bind.address=${JBOSS_IP_PUBLIC:-0}"
    # JBOSS_CONFIGURATION/PROFILE
    JBOSS_OPTS="$JBOSS_OPTS -Djboss.server.default.config=${JBOSS_CONFIG:-standalone.xml}"
else
    echo "Additional JBOSS options were alreay set to : $JBOSS_OPT"
fi

#
# Specify options to pass to the Java VM.
#
if [ "x$JAVA_OPTS" = "x" ]; then
    if [ "x$JBOSS_MODULES_SYSTEM_PKGS" = "x" ]; then
        JBOSS_MODULES_SYSTEM_PKGS="org.jboss.byteman"
    fi
    if [ "x$JVM_XMS" = "x" ]; then
        JVM_XMS=1300m
    fi
    if [ "x$JVM_XMX" = "x" ]; then
        JVM_XMX=1300m
    fi
    if [ "x$JVM_METASPACESIZE" = "x" ]; then
        JVM_METASPACESIZE=96m
    fi
    if [ "x$JVM_MAXMETASPACESIZE" = "x" ]; then
        JVM_MAXMETASPACESIZE=256m
    fi
    JAVA_OPTS="-Xms$JVM_XMS"
    JAVA_OPTS="$JAVA_OPTS -Xmx$JVM_XMX"
    JAVA_OPTS="$JAVA_OPTS -XX:MetaspaceSize=$JVM_METASPACESIZE"
    JAVA_OPTS="$JAVA_OPTS -XX:MaxMetaspaceSize=$JVM_MAXMETASPACESIZE" 
    JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true"
    JAVA_OPTS="$JAVA_OPTS -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS"
    JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true" 
    export JAVA_OPTS
fi
export JBOSS_OPTS JAVA_OPTS

JBOSS_SCRIPT=$JBOSS_HOME/bin/standalone.sh
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
export JBOSS_SCRIPT JBOSS_CLI

