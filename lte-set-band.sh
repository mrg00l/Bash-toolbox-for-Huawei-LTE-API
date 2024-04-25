#!/bin/bash
#
rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/functions.bash"

[[ $(F_checklogin) == "0" ]] && F_login

F_set-net-mode "45"

F_logout

