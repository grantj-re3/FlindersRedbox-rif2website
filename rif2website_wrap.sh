#!/bin/sh
# Usage: rif2website_wrap.sh
#
# It is recommended that this script be run by an unprivileged (non-root)
# user which has the ability to write files/dirs within the apache
# web-server's document-root.
#
# BEWARE: Commands in this script (eg. recursive rm & rsync with the
# --delete option) can/will *delete* many files/dirs from your filesystem.
# If configured badly, the deleted files/dirs may be unexpected. If
# you modify or use this script ensure you know what you are doing!
# USE THIS SCRIPT AT YOUR OWN RISK!
#
# If you wish to see what shell commands will be run by this script
# without running them, then set DRY_RUN=1 and VERBOSE=1 before executing.
#
# This script can be run from a Unix/Linux cron job. Eg.
#   30 8-18 * * 1-5 $HOME/bin/rif2website_wrap.sh >> $HOME/log/rif2website_wrap.log 2>&1
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin; export PATH

# Optionally override your OS timezone. Valid TZ values can be found at
# http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
# or under /usr/share/zoneinfo on many Linux systems.
#TZ=Australia/South; export TZ		# Eg. America/New_York or Australia/South

BIN_DIR=$HOME/opt/rif2website
EXE_FNAME=rif2website.rb

WEB_APP_LIST="mint redbox"	# One or both of "mint redbox" (space separated)

IMAGES_CSS_TARBALL=$HOME/opt/rif2website/etc/images_css.tar.gz	# Source of CSS, images, etc
HOST=`hostname -s`
VHOST="${HOST}pub"		# Apache virtual host name (eg. 'metadatastore')
WWW_PARENT=/var/www/$VHOST/md

# Make sure these paths are chosen carefully!
# Do not use a trailing slash '/' for dir names (as they change the meaning for rsync).

VERBOSE=1			# 1=Verbose mode on. Other (eg. 0) = Verbose mode off
DRY_RUN=0			# 1=Do not execute commands. Other (eg. 0) = Normal execution.

RSYNC_OPTS="-a --delete"	# Some useful options: "-av --delete --dry-run"
APP=`basename $0`		# Basename of this script

##############################################################################
# Echo with timestamp: echo_timestamp(msg)
##############################################################################
echo_timestamp() {
  echo "`date +%F\ %T` -- $1"
}

##############################################################################
# Issue warning if ruby version is unexpected: validate_ruby_version()
##############################################################################
validate_ruby_version() {
  RUBY_VERSION=1.8.7
  if ! ruby -v |grep -q "^ruby *$RUBY_VERSION"; then
    echo_timestamp "WARNING: Incompatible ruby version! Expected $RUBY_VERSION"
    sleep 3
  fi
}

##############################################################################
# Execute a shell command: do_command(cmd, is_show_cmd, msg)
##############################################################################
# - If msg is not empty, write it to stdout else do not.
# - If is_show_cmd==1, write command 'cmd' to stdout else do not.
# - Execute command 'cmd'
do_command() {
  cmd="$1"
  is_show_cmd=$2
  msg="$3"

  [ "$msg" != "" ] && echo_timestamp "$msg"
  [ $is_show_cmd = 1 ] && echo_timestamp "Command: $cmd"
  if [ $DRY_RUN != 1 ]; then
    eval $cmd
    retval=$?
    if [ $retval -ne 0 ]; then
      echo_timestamp "Error returned by command (ErrNo: $retval)" >&2
      echo_timestamp "Perhaps more details are available in logs." >&2
      exit $retval
    fi
  fi
}

##############################################################################
# Performs very basic validation on a directory string: validate_dir(dir)
##############################################################################
# This very simple validation is meant to ensure people do not do very bad
# things (eg. recursive delete at the system root dir or  system www dir).
validate_dir() {
  dir="$1"
  # Check $dir contains at least 3x '/' (each followed by 1 or
  # more alphanumeric or '-' or '_' chars).
  if ! echo "$dir" |egrep -q "^(/[a-zA-Z0-9_\-]+){3,}$"; then
    echo "Unsuitable directory: Less than 3 levels deep or unsuitable characters used or ends with '/': '$dir'"
    exit 1
  fi
  parent=`dirname "$dir"`		# Does parent of this path exist?
  if [ ! -d "$parent" ]; then
    echo "The parent of '$dir' is not a directory"
    exit 1
  fi

}

##############################################################################
# Main
##############################################################################
echo_timestamp "------------------------------"
echo_timestamp "Starting $APP"

validate_ruby_version

for web_app in $WEB_APP_LIST; do
  child_dir=`echo $web_app |cut -c1`
  PUBLIC_WEBSITE_DIR=$WWW_PARENT/$child_dir		# Target website dir. Eg. /var/www/YOUR_VHOST/metadata/m
  INTERMED_WEBSITE_DIR=${PUBLIC_WEBSITE_DIR}_temp	# Must be same as Config[:dest_root_dir] in rif2website.rb. Eg. /var/www/YOUR_VHOST/metadata/m_temp
  BACKUP_WEBSITE_DIR=${PUBLIC_WEBSITE_DIR}_back		# Backup of target website dir. Eg. /var/www/YOUR_VHOST/metadata/m_back

  for dir in $PUBLIC_WEBSITE_DIR $INTERMED_WEBSITE_DIR $BACKUP_WEBSITE_DIR; do
    [ ! -d $dir ] && mkdir -p $dir
    validate_dir "$dir"
  done

  cmd="cd \"$BIN_DIR\" && ruby $EXE_FNAME --$web_app"
  do_command "$cmd" $VERBOSE "Write *${web_app}* static pages to intermediate directory"

  cmd="tar zxpf \"$IMAGES_CSS_TARBALL\" -C \"$INTERMED_WEBSITE_DIR\""
  do_command "$cmd" $VERBOSE "Extract CSS, images, etc to intermediate directory"

  cmd="[ -d "$PUBLIC_WEBSITE_DIR" ] && rsync $RSYNC_OPTS \"$PUBLIC_WEBSITE_DIR/\" \"$BACKUP_WEBSITE_DIR\""
  do_command "$cmd" $VERBOSE "Sync the backup dir (from the production website). BEWARE: Potentially hazardous command!"

  cmd="rsync $RSYNC_OPTS \"$INTERMED_WEBSITE_DIR/\" \"$PUBLIC_WEBSITE_DIR\""
  do_command "$cmd" $VERBOSE "Sync the production website (from the intermediate dir). BEWARE: Potentially hazardous command!"

  cmd="rm -rf \"$INTERMED_WEBSITE_DIR\""
  do_command "$cmd" $VERBOSE "Remove the intermediate dir. BEWARE: Potentially hazardous command!"
done

echo_timestamp "Ending $APP"
exit 0

