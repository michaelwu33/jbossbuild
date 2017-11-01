#!/bin/sh

DIRNAME=`dirname "$0"`
PROGNAME=`basename "$0"`

if [ -f $DIRNAME/jboss-setup.flag ]; then
    echo 
    echo "JBoss instance has not been set up yet, please run $DIRNAME/jboss-setup.bash first"
    exit 1
fi

if [ -r $DIRNAME/setenv.sh ]; then
    . $DIRNAME/setenv.sh
else
    echo "ERROR: $DIRNAME/setenv.sh is not found. please check!"
    exit 1
fi

if [ -x "$JBOSS_SCRIPT" ]; then
    echo
    echo "JAVA option: $JAVA_OPTS"
    echo
    echo "JBOSS options: $JBOSS_OPTS"
    echo
    echo "Console log : $JBOSS_CONSOLE_LOG"
    $JBOSS_SCRIPT $JBOSS_OPTS > $JBOSS_CONSOLE_LOG 2>&1 
else
    echo "JBOSS startup script is not found or not executable. please check."
    echo "script was: $JBOSS_SCRIPT"
    exit 1
fi

