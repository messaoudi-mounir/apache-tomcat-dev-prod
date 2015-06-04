#! /bin/sh
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

ACTION="$1"

# Friendly Logo
logo()
{
        echo ""
        echo "  ______                           __  "
        echo " /_  __/___  ____ ___  _________ _/ /_ "
        echo "  / / / __ \/ __  __ \/ ___/ __  / __/ "
        echo " / / / /_/ / / / / / / /__/ /_/ / /_   "
        echo "/_/  \____/_/ /_/ /_/\___/\__,_/\__/   "
        echo "                                       "
        echo "                                       "
}

# Help
usage()
{
        logo
	echo "Handles the automatic startup/shutdown of any tomcat instance within the tomcat"
	echo "folder. an instance is based on convention that a folder that hosts the specified"
	echo "instance is named the same as the port number wanted."
        echo ""
        echo "usage:"
        echo "   $0 [stop|start]"
        echo ""
        echo "examples:"
        echo "   $0 start -> Starts ALL tomcat instances currently configured"
        echo "   $0 stop  -> Stops ALL tomcat instances currently configured"
        echo ""
        exit 1
}

if [ -z  "$1" ]; then
  usage
  exit 0
fi

# directory
SCRIPT=$(readlink -f $0)
DIRECTORY=`dirname $SCRIPT`

# grab all directories that look like port numbers
ports=$(ls -p $DIRECTORY | awk -F'[_/]' '/^[0-9]/ {print $1}')

# issue action against those ports
for port in $ports
do
	$DIRECTORY/run.sh "$ACTION" $port
done

