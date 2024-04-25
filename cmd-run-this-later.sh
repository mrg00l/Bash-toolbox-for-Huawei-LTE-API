#!/bin/bash
rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/functions.bash"

[[ "$1" == "" ]] && exit

logger "the process will start soon: $1"

while [ -f "$DIR/token" ]; do # We don't want to interfere with other processes
	# Sleep for 5 seconds
    	sleep 5
done

logger "Starting: $1"

F_login

$1

