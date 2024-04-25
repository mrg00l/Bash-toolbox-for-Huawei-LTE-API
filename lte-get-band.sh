#!/bin/bash
#
rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/functions.bash"

[[ $(F_checklogin) == "0" ]] && F_login

F_get-net-mode

F_logout

