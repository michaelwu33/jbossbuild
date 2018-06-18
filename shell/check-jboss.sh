#!/bin/bash

USER=`id |cut -d ')' -f 1|cut -d '(' -f 2`

if [ `ps -eo uname:20,pid,cmd |grep $USER |grep java| grep jboss|grep -c Standalone` -eq '1' ]; then
	echo "JBoss is running"
else
	echo "JBoss is NOT running"
	exit 1
fi
