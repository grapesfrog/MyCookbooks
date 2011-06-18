#!/bin/bash
#
# MongoDB Backup Script
# VER. 0.4
# More Info: http://github.com/micahwedemeyer/automongobackup
# -------------------------------------------------------
# MongoDB Backup Script 
# Last updated 31/05/2011 - GM
# VER. 0.1
# Derived from  http://github.com/micahwedemeyer/automongobackup
# modified to shutdown mongo and file copy then a tar 
# ------------------------------------------------------
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#=====================================================================
#=====================================================================
# Set the following variables to your system needs
# (Detailed instructions below variables)
#=====================================================================

# Username to access the mongo server e.g. dbuser
# Unnecessary if authentication is off
# DBUSERNAME=XXX

# Username to access the mongo server e.g. password
# Unnecessary if authentication is off
# DBPASSWORD=XXX

# Host name (or IP address) of mongo server e.g localhost
DBHOST=127.0.0.1

# Port that mongo is listening on 
DBPORT=27017

# Backup directory location e.g /backups
BACKUPDIR="/mnt/backup"
DATADIR="/mnt/data/mongo"

# Mail setup
# What would you like to be mailed to you?
# - log   : send only log file
# - files : send log file and sql files as attachments (see docs)
# - stdout : will simply output the log to the screen if run manually.
# - quiet : Only send logs if an error occurs to the MAILADDR.
MAILCONTENT="stdout"

# Set the maximum allowed email size in k. (4000 = approx 5MB email [see docs])
MAXATTSIZE="4000"

# Email Address to send mail to? (user@domain.com)
#MAILADDR=XXX


# ============================================================
# === ADVANCED OPTIONS ( Read the doc's below for details )===
#=============================================================

# Which day do you want weekly backups? (1 to 7 where 1 is Monday)
DOWEEKLY=6

# Choose Compression type. (gzip or bzip2)
COMP="gzip"

# Choose if the uncompressed folder should be deleted after compression has completed
CLEANUP="yes"

# Additionally keep a copy of the most recent backup in a seperate directory.
LATEST="yes"
# Make Hardlink not a copy
LATESTLINK="yes"

# Choose other Server if is Replica-Set Master
REPLICAONSLAVE="yes"

# Command to run before backups (uncomment to use)
#PREBACKUP="/etc/mysql-backup-pre"

# Command run after backups (uncomment to use)
#POSTBACKUP="/etc/mysql-backup-post"

#=====================================================================
# Options documentation
#=====================================================================
# Set DBUSERNAME and DBPASSWORD of a user that has at least SELECT permission
# to ALL databases.
#
# Set the DBHOST option to the server you wish to backup, leave the
# default to backup "this server".(to backup multiple servers make
# copies of this file and set the options for that server)
#
# You can change the backup storage location from /backups to anything
# you like by using the BACKUPDIR setting..
#
# The MAILCONTENT and MAILADDR options and pretty self explanitory, use
# these to have the backup log mailed to you at any email address or multiple
# email addresses in a space seperated list.
# (If you set mail content to "log" you will require access to the "mail" program
# on your server. If you set this to "files" you will have to have mutt installed
# on your server. If you set it to "stdout" it will log to the screen if run from 
# the console or to the cron job owner if run through cron. If you set it to "quiet"
# logs will only be mailed if there are errors reported. )
#
#
# Finally copy automongobackup.sh to anywhere on your server and make sure
# to set executable permission. You can also copy the script to
# /etc/cron.daily to have it execute automatically every night or simply
# place a symlink in /etc/cron.daily to the file if you wish to keep it 
# somwhere else.
# NOTE:On Debian copy the file with no extention for it to be run
# by cron e.g just name the file "automongobackup"
#
# Thats it..
#
#
# === Advanced options doc's ===
#
# To set the day of the week that you would like the weekly backup to happen
# set the DOWEEKLY setting, this can be a value from 1 to 7 where 1 is Monday,
# The default is 6 which means that weekly backups are done on a Saturday.
#
# Use PREBACKUP and POSTBACKUP to specify Per and Post backup commands
# or scripts to perform tasks either before or after the backup process.
#
#
#=====================================================================
# Backup Rotation..
#=====================================================================
#
# Daily Backups are rotated weekly..
# Weekly Backups are run by default on Saturday Morning when
# cron.daily scripts are run...Can be changed with DOWEEKLY setting..
# Weekly Backups are rotated on a 5 week cycle..
# Monthly Backups are run on the 1st of the month..
# Monthly Backups are NOT rotated automatically...
# It may be a good idea to copy Monthly backups offline or to another
# server..
#
#=====================================================================
# Please Note!!
#=====================================================================
#
# I take no resposibility for any data loss or corruption when using
# this script..
# This script will not help in the event of a hard drive crash. If a 
# copy of the backup has not be stored offline or on another PC..
# You should copy your backups offline regularly for best protection.
#
# Happy backing up...
#
#=====================================================================
# Restoring
#=====================================================================
# ???
#
#=====================================================================
# Change Log
#=====================================================================
#
# VER 0.5 - (2011-02-04) (author: Jan Doberstein)
# 	- Added replicaset support (don't Backup on Master)
# 	- Added Hard Support for 'latest' Copy
# 
# VER 0.4 - (2010-10-26)
# - Cleaned up warning message to make it clear that it can usually be
# safely ignored
#
# VER 0.3 - (2010-06-11)
# - Added the DBPORT parameter
# - Changed USERNAME and PASSWORD to DBUSERNAME and DBPASSWORD
# - Fixed some bugs with compression
#
# VER 0.2 - (2010-05-27) (author: Gregory Barchard)
# 	-Added back the compression option for automatically creating
#	tgz or bz2 archives
#	-Added a cleanup option to optionally remove the database dump
#	after creating the archives
#	-Removed unnecessary path additions
#
# VER 0.1 - (2010-05-11)
#   Initial Release
#
#=====================================================================
#=====================================================================
#=====================================================================
#
# Should not need to be modified from here down!!
#
#=====================================================================
#=====================================================================
#=====================================================================
PATH=/usr/local/bin:/usr/bin:/bin
DATE=`date +%Y-%m-%d_%Hh%Mm`				# Datestamp e.g 2002-09-21
DOW=`date +%A`							# Day of the week e.g. Monday
DNOW=`date +%u`						# Day number of the week 1 to 7 where 1 represents Monday
DOM=`date +%d`							# Date of the Month e.g. 27
M=`date +%B`							# Month e.g January
W=`date +%V`							# Week Number e.g 37
VER=0.4									# Version Number
LOGFILE=$BACKUPDIR/$DBHOST-`date +%N`.log		# Logfile Name
LOGERR=$BACKUPDIR/ERRORS_$DBHOST-`date +%N`.log		# Logfile Name
BACKUPFILES=""
OPT=""			# OPT string for use with mongodump

# Do we need to use a username/password?
if [ "$DBUSERNAME" ]
  then 
  OPT="$OPT --username=$DBUSERNAME --password=$DBPASSWORD"
fi

# Create required directories
if [ ! -e "$BACKUPDIR" ]		# Check Backup Directory exists.
	then
	mkdir -p "$BACKUPDIR"
fi

if [ ! -e "$BACKUPDIR/dump" ]		# Check dump Directory exists.
	then
	mkdir -p "$BACKUPDIR/dump"
fi

if [ ! -e "$BACKUPDIR/daily" ]		# Check Daily Directory exists.
	then
	mkdir -p "$BACKUPDIR/daily"
fi

if [ ! -e "$BACKUPDIR/weekly" ]		# Check Weekly Directory exists.
	then
	mkdir -p "$BACKUPDIR/weekly"
fi

if [ ! -e "$BACKUPDIR/monthly" ]	# Check Monthly Directory exists.
	then
	mkdir -p "$BACKUPDIR/monthly"
fi

if [ "$LATEST" = "yes" ]
then
	if [ ! -e "$BACKUPDIR/latest" ]	# Check Latest Directory exists.
	then
		mkdir -p "$BACKUPDIR/latest"
	fi
eval rm -fv "$BACKUPDIR/latest/*"
fi

# IO redirection for logging.
touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.
touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.


# Functions

# Database dump function
# deprecated functions as refactoring to get this to work properly is being called within mongo
dbdump () {
mongodump --host=$DBHOST:$DBPORT --out=$1 $OPT
return 0
}
#mongo lock
lockmongo () {
mongo admin /etc/chef/shutdownmongo.js
return 0
}

unlockmongo () {
#mongo admin /etc/chef/fsyncunlock.js
/etc/init.d/mongod start
return 0
}
# end deprecated functions


# Compression function plus latest copy
SUFFIX=""
compression () {
if [ "$COMP" = "gzip" ]; then
  SUFFIX=".tgz"
  echo Tar and gzip to "$2$SUFFIX"
#	cd $1 && tar -cvzf "$2$SUFFIX" "$2"
   cd $1 && tar -cvzf "$2$SUFFIX" "$BACKUPDIR/dump"
elif [ "$COMP" = "bzip2" ]; then
  SUFFIX=".tar.bz2"
  echo Tar and bzip2 to "$2$SUFFIX"
	cd $1 && tar -cvjf "$2$SUFFIX" "$2"
else
	echo "No compression option set, check advanced settings"
fi
if [ "$LATEST" = "yes" ]; then
	if [ "$LATESTLINK" = "yes" ];then
		COPY="cp -l"
	else
		COPY="cp"
	$COPY $1$2$SUFFIX "$BACKUPDIR/latest/"
	fi
fi
if [ "$CLEANUP" = "yes" ]; then
	echo Cleaning up folder at "$1$2"
	rm -rf "$1$2"
fi	
return 0
}

# Run command before we begin
if [ "$PREBACKUP" ]
	then
	echo ======================================================================
	echo "Prebackup command output."
	echo
	eval $PREBACKUP
	echo
	echo ======================================================================
	echo
fi

# Hostname for LOG information
if [ "$DBHOST" = "localhost" ]; then
	HOST=`hostname`
	if [ "$SOCKET" ]; then
		OPT="$OPT --socket=$SOCKET"
	fi
else
	HOST=$DBHOST
fi

# Replicaset Choose Slave if Master
if [ "REPLICAONSLAVE" = "yes" ];then
	DBHOST=$(mongo --host $DBHOST --quiet --eval "var im = rs.isMaster(); if(im.ismaster && im.hosts) { im.hosts[2] } else { '$DBHOST' }")
fi
	
echo ======================================================================
echo AutoMongoBackup VER $VER
echo 
echo Backup of Database Server - $HOST on $DBHOST
echo ======================================================================

echo Backup Start `date`
echo ======================================================================
	# Monthly Full Backup of all Databases
	if [ $DOM = "01" ]; then
		echo Monthly Full Backup
		 # dbdump "$BACKUPDIR/monthly/$DATE.$M"
	
		  rm -f  $BACKUPDIR/dump/*
		  cp $DATADIR/ph*  $BACKUPDIR/dump/ 
		
		  compression "$BACKUPDIR/monthly/" "$DATE.$M"
		echo ----------------------------------------------------------------------
	fi

	# Weekly Backup
	if [ $DNOW = $DOWEEKLY ]; then
		echo Weekly Backup
		echo
		echo Rotating 5 weeks Backups...
			if [ "$W" -le 05 ];then
				REMW=`expr 48 + $W`
			elif [ "$W" -lt 15 ];then
				REMW=0`expr $W - 5`
			else
				REMW=`expr $W - 5`
			fi
		eval rm -fv "$BACKUPDIR/weekly/week.$REMW.*" 
		echo
		#	dbdump "$BACKUPDIR/weekly/week.$W.$DATE"
		
			 rm -f  $BACKUPDIR/dump/*
			cp $DATADIR/ph*  $BACKUPDIR/dump/ 
			  
			compression "$BACKUPDIR/weekly/" "week.$W.$DATE"
		echo ----------------------------------------------------------------------
		
	# Daily Backup
	else
		echo Daily Backup of Databases
		echo
		echo Rotating last weeks Backup...
		eval rm -fv "$BACKUPDIR/daily/*.$DOW.*" 
		echo
		#	dbdump "$BACKUPDIR/daily/$DATE.$DOW"
		
			rm -f  $BACKUPDIR/dump/*
			cp $DATADIR/ph*  $BACKUPDIR/dump/ 
			 
			compression "$BACKUPDIR/daily/" "$DATE.$DOW"
		echo ----------------------------------------------------------------------
	fi
echo Backup End Time `date`
echo ======================================================================

echo Total disk space used for backup storage..
echo Size - Location
echo `du -hs "$BACKUPDIR"`
echo
echo ======================================================================

# Run command when we're done
if [ "$POSTBACKUP" ]
	then
	echo ======================================================================
	echo "Postbackup command output."
	echo
	eval $POSTBACKUP
	echo
	echo ======================================================================
fi

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

if [ "$MAILCONTENT" = "log" ]
then
	cat "$LOGFILE" | mail -s "Mongo Backup Log for $HOST - $DATE" $MAILADDR
	if [ -s "$LOGERR" ]
		then
			cat "$LOGERR" | mail -s "ERRORS REPORTED: Mongo Backup error Log for $HOST - $DATE" $MAILADDR
	fi
else
	if [ -s "$LOGERR" ]
		then
			cat "$LOGFILE"
			echo
			echo "###### WARNING ######"
			echo "STDERR written to during mongodump execution."
			echo "The backup probably succeeded, as mongodump sometimes writes to STDERR, but you may wish to scan the error log below:"
			cat "$LOGERR"
	else
		cat "$LOGFILE"
	fi	
fi

# TODO: Would be nice to know if there were any *actual* errors in the $LOGERR
STATUS=1

# Clean up Logfile
eval rm -f "$LOGFILE"
eval rm -f "$LOGERR"

exit $STATUS