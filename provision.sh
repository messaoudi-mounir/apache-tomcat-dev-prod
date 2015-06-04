#!/bin/bash
# ==================================================================
#  ______                           __
# /_  __/___  ____ ___  _________ _/ /_
#  / / / __ \/ __ `__ \/ ___/ __ `/ __/
# / / / /_/ / / / / / / /__/ /_/ / /_
#/_/  \____/_/ /_/ /_/\___/\__,_/\__/

# Multi-instance Apache Tomcat installation with a focus
# on best-practices as defined by Apache, SpringSource, and MuleSoft
# and enterprise use with large-scale deployments.

# ==================================================================
# standard variables
SCRIPT=`perl -e 'use Cwd "abs_path";print abs_path(shift)' $0`
DIRECTORY=`dirname $SCRIPT`

ACTION=$1
HTTP_PORT=$2
export CATALINA_BASE="$DIRECTORY/$HTTP_PORT"

# IP ADDRESS OF CURRENT MACHINE
if hash ip 2>&-
then
  IP=`ip addr show | grep 'global eth[0-9]' | grep -o 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' | grep -o '[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'`
else
  IP=`ifconfig | grep 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+.*broadcast' | grep -o 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' | grep -o '[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'`
fi

# Friendly Logo
logo()
{
  echo ""
  echo "  ______                           __    "
  echo " /_  __/___  ____ ___  _________ _/ /_   "
  echo "  / / / __ \/ __  __ \/ ___/ __  / __/   "
  echo " / / / /_/ / / / / / / /__/ /_/ / /_     "
  echo "/_/  \____/_/ /_/ /_/\___/\__,_/\__/     "
  echo "                                         "
  echo "                                         "
}

# Help
usage()
{
  logo
  echo "Script creates or deletes a Tomcat 7 web instance by"
  echo "provisioning them from the shared/template folder."
  echo ""
  echo "usage:"
  echo "   $0 [create|delete] <port>"
  echo ""
  echo "examples:"
  echo "   $0 create 8080   -> Creates a new tomcat instance on port 8080"
  echo "   $0 delete 8080   -> Deletes the tomcat instance on port 8080"
  echo "   $0 update 8080   -> Update the tomcat instance on port 8080 to the latest version"
  echo ""
  exit 1
}

# compare the latest version with the one currently
# installed if different upgrade it
upgrade_tomcat()
{
  check_tomcat_version_is_latest

  # is latest version the same, if not we need to be!
  if [ "$LATEST_TOMCAT_VERSION" != "$CURRENT_TOMCAT_VERSION" ]; then
    # ensure we have the specified tomcat on disk, if not go out and download it
    if [ ! -d "$DIRECTORY/$LATEST_TOMCAT_VERSION" ]; then
      curl -L "https://s3.amazonaws.com/repo.tomcat.apache.org/$LATEST_TOMCAT_MAJOR_VERSION_NUMBER/$LATEST_TOMCAT_VERSION.zip" -o "$DIRECTORY/$LATEST_TOMCAT_VERSION.zip"
      RESULT=$?
      if [ ! $RESULT -eq 0 ]; then
        echo "Failed to download tomcat at https://s3.amazonaws.com/repo.tomcat.apache.org/$LATEST_TOMCAT_MAJOR_VERSION_NUMBER/$LATEST_TOMCAT_VERSION.zip"
        exit 1
      fi

      echo "Extracting Tomcat..."
      unzip $DIRECTORY/$LATEST_TOMCAT_VERSION.zip
      echo "Removing downloaded zip..."
      rm -rf $DIRECTORY/$LATEST_TOMCAT_VERSION.zip
      echo "Changing scripts to executable..."
      chmod +x $DIRECTORY/$LATEST_TOMCAT_VERSION/bin/*.sh
    fi

    echo "Setting $HTTP_PORT to use $LATEST_TOMCAT_VERSION..."
    echo "$LATEST_TOMCAT_VERSION" > $DIRECTORY/$HTTP_PORT/VERSION
    echo "Completed Upgrade of Tomcat from $CURRENT_TOMCAT_VERSION to $LATEST_TOMCAT_VERSION"

  fi

  if [ "$LATEST_TOMCAT_VERSION" = "$CURRENT_TOMCAT_VERSION" ]; then
    echo "Upgrade not required latest version is applied to port $HTTP_PORT"
  fi

}

check_tomcat_version_is_latest() {
  # grab current tomcat version from file system of port (will be in format apache-tomcat-X.XX.XX)
  export CURRENT_TOMCAT_VERSION=`cat $DIRECTORY/$HTTP_PORT/VERSION`
  export CURRENT_TOMCAT_MAJOR_VERSION_NUMBER=`echo $CURRENT_TOMCAT_VERSION | egrep -o 'apache-tomcat-[[:digit:]]{1}' | egrep -o '[[:digit:]]{1}'` 

  # Get latest version for $MAJOR version number (7,6,8?) and compare that version number to one applied to port
  export LATEST_TOMCAT_VERSION=`curl -L "https://s3.amazonaws.com/repo.tomcat.apache.org/$CURRENT_TOMCAT_MAJOR_VERSION_NUMBER/RELEASE" -o "$DIRECTORY/tmp.txt" | cat $DIRECTORY/tmp.txt`
  export LATEST_TOMCAT_MAJOR_VERSION_NUMBER=`echo $LATEST_TOMCAT_VERSION | egrep -o 'apache-tomcat-[[:digit:]]{1}' | egrep -o '[[:digit:]]{1}'`

}

# Download and install Tomcat
choose_tomcat_version()
{
  echo ""
  echo "What version of tomcat would you like to provision:"
  cat VERSION | awk 'NR % 1 == 0' | awk '{ print "Enter [" $1 "] for " $2 }'
  echo -n "Enter your choice: "
  read -e CHOICE
  export CURRENT_TOMCAT_VERSION=`cat $DIRECTORY/VERSION | grep ^$CHOICE | grep -oE apache.+`

  if [ -z $CURRENT_TOMCAT_VERSION ]; then
    echo "ERROR: Unable to identify the tomcat version you have selected, '$CHOICE' is not an option to choose from."
    exit 1
  fi

  # grab major version number from current version so that we can query
  # what the latest version is from central repository
  export CURRENT_TOMCAT_VERSION_NUMBER=`echo "$CURRENT_TOMCAT_VERSION" | egrep -o 'apache-tomcat-[[:digit:]]{1}' | egrep -o '[[:digit:]]{1}'`

  # Get latest version for $MAJOR version number (7,6,8?) and compare that version number to one applied to port
  curl -L "https://s3.amazonaws.com/repo.tomcat.apache.org/$CURRENT_TOMCAT_VERSION_NUMBER/RELEASE" -o "$DIRECTORY/tmp.txt"
  export LATEST_TOMCAT_VERSION=`cat $DIRECTORY/tmp.txt`
  export LATEST_TOMCAT_MAJOR_VERSION_NUMBER=`echo "$LATEST_TOMCAT_VERSION" | egrep -o 'apache-tomcat-[[:digit:]]{1}' | egrep -o '[[:digit:]]{1}'`

  echo "Latest Version of Tomcat: $LATEST_TOMCAT_VERSION ($LATEST_TOMCAT_MAJOR_VERSION_NUMBER) vs. $CURRENT_TOMCAT_VERSION ($CURRENT_TOMCAT_VERSION_NUMBER)"

  # ensure we have the specified tomcat on disk, if not go out and download it
  if [ ! -d "$DIRECTORY/$LATEST_TOMCAT_VERSION" ]; then
    echo "Downloading... https://s3.amazonaws.com/repo.tomcat.apache.org/$LATEST_TOMCAT_MAJOR_VERSION_NUMBER/$LATEST_TOMCAT_VERSION.zip"
    curl -L "https://s3.amazonaws.com/repo.tomcat.apache.org/$LATEST_TOMCAT_MAJOR_VERSION_NUMBER/$LATEST_TOMCAT_VERSION.zip" -o "$DIRECTORY/$LATEST_TOMCAT_VERSION.zip"
    RESULT=$?
    if [ ! $RESULT -eq 0 ]; then
      echo "Failed to download tomcat at https://s3.amazonaws.com/repo.tomcat.apache.org/$LATEST_TOMCAT_MAJOR_VERSION_NUMBER/$LATEST_TOMCAT_VERSION.zip"
      exit 1
    fi

    echo "Extracting Tomcat..."
    unzip $DIRECTORY/$LATEST_TOMCAT_VERSION.zip
    echo "Removing downloaded zip..."
    rm -rf $DIRECTORY/$LATEST_TOMCAT_VERSION.zip
    echo "Changing scripts to executable..."
    chmod +x $DIRECTORY/$LATEST_TOMCAT_VERSION/bin/*.sh

  fi

  echo "[Step 1 of 2]: Creating new instance '$CATALINA_BASE'..."
  cp -R $DIRECTORY/shared/template $DIRECTORY/$HTTP_PORT

  echo "[Step 2 of 2]: Setting Tomcat version to $LATEST_TOMCAT_VERSION..."
  echo "$LATEST_TOMCAT_VERSION" > $DIRECTORY/$HTTP_PORT/VERSION

  echo "[Done]: Your tomcat instance can now be started via '$DIRECTORY/run.sh start $HTTP_PORT'..."
}

# Main
# if no arguments passed in
if [ $# -lt 1 ]; then
  usage
fi

if [ -z  "$ACTION" -o -z "$HTTP_PORT" ]; then
  usage
  exit 1
fi

# ask for tomcat version
case $ACTION in
  check)
    if [ ! -d "$CATALINA_BASE" ]; then
      echo "error: that port does not exist to update"
      exit 1
    fi

    logo
    check_tomcat_version_is_latest
    if [ "$LATEST_TOMCAT_VERSION" != "$CURRENT_TOMCAT_VERSION" ]; then
      echo "Upgrade is available for $HTTP_PORT from $CURRENT_TOMCAT_VERSION to $LATEST_TOMCAT_VERSION"
    fi
    if [ "$LATEST_TOMCAT_VERSION" = "$CURRENT_TOMCAT_VERSION" ]; then
      echo "No upgrade required for $HTTP_PORT it is already running latest version $LATEST_TOMCAT_VERSION"
    fi
    
  ;;
  upgrade)
    if [ ! -d "$CATALINA_BASE" ]; then
      echo "error: that port does not exist to update"
      exit 1
    fi

    logo
    upgrade_tomcat
  ;;
  create)
    if [ -d "$CATALINA_BASE" ]; then
      echo "error: the defined port is already claimed"
      exit 1
    fi

    logo
    choose_tomcat_version

    exit 0
  ;;
  delete)
    if [ ! -d "$CATALINA_BASE" ]; then
      echo "error: that port does not exist to delete"
      exit 1
    fi

    logo
    echo "Removing tomcat instance '$CATALINA_BASE'"
    echo -n "Are you sure? [y/N]: "
    read -e CONFIRM

    case $CONFIRM in
      [yY]*)
        echo "Step [1 of 3]: Ensuring instance $HTTP_PORT is shutdown..."
        $DIRECTORY/run.sh stop $HTTP_PORT > /dev/null 2>&1
        sleep 1
        echo "Step [2 of 3]: Ensuring no orphaned tomcat instances are running..."
        kill -9 `pgrep -f '\-Dhttp.port=$HTTP_PORT'` > /dev/null 2>&1
        sleep 1
        echo "Step [3 of 3]: Removing instance from file system..."
        rm -rf $CATALINA_BASE
        echo "(done)"
        exit 0
        ;;
      [nN]*)
        exit "(aborted)"
        ;;
      *)
        echo "(aborted)"
        ;;
    esac
  ;;
esac
exit 0
