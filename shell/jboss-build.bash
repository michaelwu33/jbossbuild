#!/bin/bash
#
# Build JBOSS
#
#       run as: root
#       Usage : /path/to/jboss-build.bash
#
#       Author: Michael Wu
#

# build script must be run by 'root'
if [ `id -u` != 0 ]; then
	echo
	echo "super user 'root' is required to run build script! quiting..."
	echo
	exit 1
fi

#
# app home
#
while :
do
	clear
	echo
	echo "Setting up application home..."
	echo "    The home should be created already by AMS while MSO and RUN account"
	echo "    were being created, because their home should be under it as per "
	echo "    bank standard. Usually it is under /opt with proper ownership and "
	echo "    permission."
	echo
	read -p "Please specify a home directory for application (e.g. /opt/<app-home>): " APP_HOME

	if [ -z $APP_HOME ]; then
	        echo
                read -p "You haven't specify anything, are you sure to quit? press y to quit..." TEMPKEY
                TEMPKEY=${TEMPKEY^^}
                if [ "$TEMPKEY" = "Y" ] || [ "$TEMPKEY" = "YES" ]; then
			echo; exit 1
		else
			continue
                fi
	fi

	if [ ! -d $APP_HOME ]; then
		echo
		read -p "$APP_HOME does not exist, press y to specify a new home, other to quit..." TEMPKEY
		TEMPKEY=${TEMPKEY^^}
		if [ "$TEMPKEY" = "Y" ] || [ "$TEMPKEY" = "YES" ]; then
			continue
		fi
		echo
		exit 1
	fi

	# Do we really care about where is the home directory of MSO/RUN?
	# TODO
	if [ ! -d $APP_HOME/home ]; then
		echo
		echo "Oooops, I don't see a user home directory under $APP_HOME."
		echo "Usually it should be there for MSO/Run accounts."
		echo
		read -p "Do you want to specify a new application home? press y to continue, other to quit..." TEMPKEY
                TEMPKEY=${TEMPKEY^^}
                if [ "$TEMPKEY" = "Y" ] || [ "$TEMPKEY" = "YES" ]; then
                        continue
                fi
                echo
                exit 1
	fi

	if [ -d $APP_HOME/Middleware ]; then
		echo
		echo "$APP_HOME/Middleware is already there, it could be using by other application."
		echo "If it is no longer in use, please remove it explicitely then do build again."
		echo "Or please specify a new appliation home to continue."
		echo
                read -p "Do you want to specify a new application home? press y to continue, other to quit..." TEMPKEY
                TEMPKEY=${TEMPKEY^^}
                if [ "$TEMPKEY" = "Y" ] || [ "$TEMPKEY" = "YES" ]; then
                        continue
                fi
                echo
                exit 1
        fi

	# all good
	break
done
#Now we have $APP_HOME

#
# mso, run, grp
#
while :
do
	clear
	unset MSO_USER GID_MSO_USER HOME_MSO_USER SHELL_MSO_USER
	unset RUN_USER GID_RUN_USER HOME_RUN_USER SHELL_RUN_USER
	unset GRP_USER ID_GRP_USER 
	echo "Specify MSO, Run, and Group ..."
	echo "    AMS to create these accounts and group. They must be created before build work."
	echo "    The home directory of MSO/RUN must be under $APP_HOME/home/, and shell should"
	echo "    be /bin/bash, and primary group of MSO/RUN should be <group>."
	echo "If those conditions haven't been met yet, press ctrl+c to quit build work. Do build"
	echo "again once issue is fixed."
	echo 
	read -p "MSO account: " MSO_USER
	read -p "RUN account: " RUN_USER
	read -p "Their GROUP: " GRP_USER

	if [ -z "$MSO_USER" -o -z "$RUN_USER" -o -z "$GRP_USER" ]; then
		echo
		read -p "Account or Group can not be empty!, please any key to re-enter, ctrl+c to quit ..."
		continue
	fi

	# MSO/RUN set to same account?
	if [ "$MSO_USER" = "$RUN_USER" ]; then
		echo "\nMSO and RUN are same, are you sure?"
		read -p "Press y to continue, other key to re-enter, ctrl+c to quit..." TEMPKEY
                TEMPKEY=${TEMPKEY^^}
                if [ "$TEMPKEY" = "Y" -o "$TEMPKEY" = "YES" ]; then
			:
		else
			continue
                fi
	fi

	#group
	grep $GRP_USER /etc/group > /tmp/$$
	while read LINE
	do
		if [ "`echo $LINE | cut -d':' -f1`" = "$GRP_USER" ]; then
			ID_GRP_USER=`echo $LINE | cut -d':' -f3`
			break
		fi
	done < /tmp/$$
	if [ -z "$ID_GRP_USER" ]; then
		echo
		read -p "Group $GRP_USER does not exist! press any key to re-enter, ctrl+c to quit..."
		continue
	fi
	# Now we have group ID of $GRP_USER

	# MSO
	grep $MSO_USER /etc/passwd > /tmp/$$
	while read LINE; do
		if [ "`echo $LINE | cut -d':' -f1`" = "$MSO_USER" ]; then
			GID_MSO_USER=`echo $LINE | cut -d':' -f4`
			HOME_MSO_USER=`echo $LINE | cut -d':' -f6`
			SHELL_MSO_USER=`echo $LINE | cut -d':' -f7`
			break
		fi
	done < /tmp/$$
	if [ -z "$GID_MSO_USER" ]; then
		echo
		read -p "MSO ACCOUNT $MSO_USER does not exist! press any key to re-enter, ctrl+c to quit..."
		continue
	fi
	# Now we have MSO and its GID, home, and shell

	# RUN		
	grep $RUN_USER /etc/passwd > /tmp/$$
	while read LINE; do
		if [ "`echo $LINE | cut -d':' -f1`" = "$RUN_USER" ]; then
			GID_RUN_USER=`echo $LINE | cut -d':' -f4`
			HOME_RUN_USER=`echo $LINE | cut -d':' -f6`
			SHELL_RUN_USER=`echo $LINE | cut -d':' -f7`
			break
		fi
	done < /tmp/$$
	if [ -z "$GID_RUN_USER" ]; then
		echo
		read -p "RUN ACCOUNT $MSO_USER does not exist! press any key to re-enter, ctrl+c to quit..."
		continue
	fi

	# MSO/RUN 's primary group should be $GRP_USER
	if [ "$GID_MSO_USER" != "$ID_GRP_USER" -o "$GID_RUN_USER" != "$ID_GRP_USER" ]; then
		echo "\nMSO and RUN accounts should have same primary group as '$GRP_USER', Please check!"
		read -p "Press any key to re-enter, ctrl+c to quit..."
		continue
	fi

	# MSO/RUN 's shell should be /bin/bash
	if [ "$SHELL_MSO_USER" != "/bin/bash" -o "$SHELL_RUN_USER" != "/bin/bash" ]; then
		echo "\nMSO/RUN account's shell should set to /bin/bash."
		read -p "Press any key to re-enter, ctrl+c to quit..."
		continue
	fi

	# MSO/RUN's home directory should under $APP_HOME?
	# TODO		
	if [ ! -d $HOME_MSO_USER -o ! -d $HOME_RUN_USER ]; then
		echo "\nThe home directory of MSO/RUN doesn't exist, please chekc!"
		read -p "Press any key to re-enter, ctrl+c to quit..."
		continue
	fi

	# all good
	break
done
# Now we have MSO/RUN/GRP and their GID/HOME

#
# JBOSS tarball
#
while :; do
	clear
	echo
	echo "Specify JBOSS package ..."
	echo "    The package is provided by Middleware team. Currently it must be available"
	echo "    locally for installation. It is a tarball with file extension .tar.gz"
	echo
	read -p "Where is the package file? :" TARBALL 

	if [ -z "$TARBALL" ]; then
		echo; echo "Please enter something!"; read
		continue
	fi

	# if the tarball file exists and readable
	if [ ! -f $TARBALL ] || [ ! -r $TARBALL ]; then
		echo
		echo "Specified Jboss tarball does not exist, or is not readable. Please check!"
		read
		continue
	fi

	# if the tarball file is a valid gzip format
	file $TARBALL >/tmp/$$ 2>&1; grep 'gzip compressed data' /tmp/$$ >/dev/null 2>&1
	if [ $? -eq 1 ]; then
		echo
		echo "Error: $TARBALL is not a valid gzip tarball. Please check!"; read
		continue
	fi

	# all good
	break
done
# Now we have $TARBALL

# Doc test
#TARBALL=/opt/michwu/src/jboss.tar.gz
#APP_HOME=/opt/michwu
#MSO_USER=michwumso
#RUN_USER=michwurun
#GRP_USER=michwugrp
#HOME_RUN_USER=/opt/michwu/home/michwurun

JBOSS_HOME=$APP_HOME/Middleware/MiddlewareApp
JAVA_HOME=$APP_HOME/Middleware/JAVA
JBOSS_CUSTOM_SCRIPT_DIR=$APP_HOME/Middleware/scripts
JBOSS_SERVER_BASE_DIR=$JBOSS_HOME/standalone

#
# Summary and confirmation
#
while :; do
	clear; echo; echo

	cat <<EOF
Summary:
    JBoss binary package file: $TARBALL
    Application Home         : $APP_HOME
    MSO Account              : $MSO_USER
    RUN Account              : $RUN_USER
    Group for MSO/RUN        : $GRP_USER    

Based on above setting, JBOSS will have below default setting:
    Java Home                : $JAVA_HOME
    JBoss Binary Home        : $JBOSS_HOME
    JBoss Custom Script Dir  : $JBOSS_CUSTOM_SCRIPT_DIR
    JBoss Server Base Dir    : $JBOSS_SERVER_BASE_DIR

EOF
	read -p "Press 'y' to continue installation, 'q' to quit ..." TEMPKEY
    TEMPKEY=${TEMPKEY^^}
    if [ "$TEMPKEY" = "Y" -o "$TEMPKEY" = "YES" ]; then
		break
	elif [ "$TEMPKEY" = "Q" -o "$TEMPKEY" = "QUIT" ]; then
		echo
		exit 1
	fi
done

#
# Extracting pakcage to destination
#
#
rm -rf $APP_HOME/Middleware
#
clear; echo; echo "Extracting JBoss package to destination..."
if [ -d $APP_HOME/Middleware ]; then
	echo; echo "Error: Destination folder $APP_HOME/Middleware is already there. Quiting..."
	exit 1
fi

# showing progress bar
touch /tmp/jbossbuild.log
( while [ -f /tmp/jbossbuild.log ]; do 
	echo -n '.'
	sleep 1
  done &
)

# extracting JBoss binart taball
tar xfz $TARBALL -C $APP_HOME/ > /tmp/jbossbuild.log 2>&1
if [ $? -eq 1 ]; then
	echo; 
	echo "Error: something is wrong when package was being extracted."
	echo "Check file /tmp/jbossbuild.log for details."
	echo "Quiting ..."
	exit 1
fi	

# Save environment variables
ENVFILE="$JBOSS_CUSTOM_SCRIPT_DIR/env-jboss.conf"
echo "JAVA_HOME=$JAVA_HOME" > $ENVFILE
echo "APP_HOME=$APP_HOME" >> $ENVFILE
echo "JBOSS_HOME=$JBOSS_HOME" >> $ENVFILE
echo "MSO_USER=$MSO_USER" >> $ENVFILE
echo "RUN_USER=$RUN_USER" >> $ENVFILE
echo "GRP_USER=$GRP_USER" >> $ENVFILE
echo "JBOSS_CUSTOM_SCRIPT_DIR=$JBOSS_CUSTOM_SCRIPT_DIR" >> $ENVFILE
echo "JBOSS_SERVER_BASE_DIR=$JBOSS_SERVER_BASE_DIR" >> $ENVFILE
echo "JBOSS_USER=$RUN_USER" >> $ENVFILE
echo "JBOSS_MODE=standalone" >> $ENVFILE
echo "JBOSS_PORT_OFFSET=0" >> $ENVFILE
echo "JBOSS_IP_MANAGEMENT=0" >> $ENVFILE
echo "JBOSS_IP_PUBLIC=0" >> $ENVFILE
echo "JVM_XMS=1300m" >> $ENVFILE
echo "JVM_XMX=1300m" >> $ENVFILE
echo "JVM_METASPACESIZE=96m" >> $ENVFILE
echo "JVM_MAXMETASPACESIZE=256m" >> $ENVFILE


# Move tarball to repository for backup
REPO_HOME="$APP_HOME/Repositories"
if [ ! -d $REPO_HOME ]; then
    mkdir -p $REPO_HOME
    chown $MSO_USER:$GRP_USER $REPO_HOME
fi
NEWTARBALL="$REPO_HOME/`basename $TARBALL`.`date +%Y%m%d`"
cp $TARBALL $NEWTARBALL >/dev/null 2>&1
chown $MSO_USER:$GRP_USER $NEWTARBALL
chmod 640 $NEWTARBALL

# Set Ownership and permission
chown -R $MSO_USER:$GRP_USER $APP_HOME/Middleware
chown -R $RUN_USER $JBOSS_CUSTOM_SCRIPT_DIR
chown -R $RUN_USER $JBOSS_SERVER_BASE_DIR
chmod 700 $JBOSS_CUSTOM_SCRIPT_DIR/*

# RUN account's user profile
BASHFILE="$HOME_RUN_USER/.bashrc"
if [ ! -f $BASHFILE ]; then
    touch $BASHFILE
    chown $RUN_USER:$GRP_USER $BASHFILE
    chmod 600 $BASHFILE
fi
echo >> $BASHFILE
echo "# Added by JBoss installation @`date +%m/%d/%Y`" >> $BASHFILE
echo "# Directory to keep customize JBoss operation scripts" >> $BASHFILE
echo "#" >> $BASHFILE
echo "export JBOSS_CUSTOM_SCRIPT_DIR=$JBOSS_CUSTOM_SCRIPT_DIR" >> $BASHFILE
echo >> $BASHFILE
echo 'export PATH=$JBOSS_CUSTOM_SCRIPT_DIR:$PATH' >> $BASHFILE

# Clean up
rm -f /tmp/jbossbuild.log; sleep 3

# Installation completed
echo
echo "JBoss binary installation has been completed succefully."
echo "The JBoss package file has been copied to $REPO_HOME/ as `basename $NEWTARBALL`"
echo 
echo "Press and key to continue ..."
read

#
# Setting up JBoss instance
#
while :; do
    clear
    cat  <<EOF

It is recommended to configure JBoss instance before starting it up. You can
specify some important JBoss instance settings like Web Admin Console, Port
Offset, Management IP, Public IP, and so on.

Do you want to configure JBoss instance for now?

EOF
    read -p "Press Y to configure, Q to end installation." TEMPKEY
    TEMPKEY=${TEMPKEY^^}
    if [ "$TEMPKEY" = "Y" -o "$TEMPKEY" = "YES" ]
    then
        # configure JBoss instance
        su - $RUN_USER -c $JBOSS_CUSTOM_SCRIPT_DIR/jboss-setup.bash
        #su - $RUN_USER -c /opt/michwu/src/Middleware/scripts/jboss-setup.bash
		break
	elif [ "$TEMPKEY" = "Q" -o "$TEMPKEY" = "QUIT" ]
	then
	    break
	fi
done

if [ -f $JBOSS_CUSTOM_SCRIPT_DIR/jboss-setup.flag ]; then
    # JBoss has not been set up yet
    echo
    echo "You haven't configured JBoss instance yet, you can do it later on. "
    echo "To configure, login as run user $RUN_USER, then run"
    echo
    echo "$JBOSS_CUSTOM_SCRIPT_DIR/jboss-setup.bash"
    echo
    read -p "Press any key to continue ..."
fi

clear
cat <<EOF

Congratulations! You are done the installation.

Login as run user $RUN_USER,
To start JBoss: $JBOSS_CUSTOM_SCRIPT_DIR/start-jboss.sh
To stop JBoss : $JBOSS_CUSTOM_SCRIPT_DIR/stop-jboss.sh

EOF
echo

exit 0


