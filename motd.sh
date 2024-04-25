#!/bin/bash
rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/functions.bash"

# You can add this script, for example to /etc/update-motd.d/15-custom

DIR="/dev/shm/motd" # MOTD running from Root, don't use default DIR.

[[ $(F_checklogin) == "0" ]] && F_login

response=$(curl -k -s -i -b $DIR/cookie $URL/api/device/signal)
TOWER=$(echo "$response" | grep -oP '<enodeb_id>\K[^<]*')
CELL=$(echo "$response" | grep -oP '<cell_id>\K[^<]*')
BAND=$(echo "$response" | grep -oP '<band>\K[^<]*')
SNR=$(echo "$response" | grep -oP '<sinr>\K[^<]*')
ULBW=$(echo "$response" | grep -oP '<ulbandwidth>\K[^<]*')
DLBW=$(echo "$response" | grep -oP '<dlbandwidth>\K[^<]*')

echo "-----------LTE----------"
UT="$(F_uptime)"
echo "Uptime: $(F_convert-seconds $UT)"
echo
echo "TOWER: $TOWER"
echo "CELL: $CELL"
echo "BAND: $BAND"
echo "SNR: $SNR"
echo "ULBW: $ULBW"
echo "DLBW: $DLBW"
echo "Net mode: $(F_get-net-mode)"
echo
F-lte-month-stats
echo "Data DW: $(F_convert-bytes $MONTHDOWN)"
echo "Data UP: $(F_convert-bytes $MONTHUP)"
echo "Data Total: $(F_convert-bytes $((MONTHUP + MONTHDOWN)))"
echo "Last cleared: $MONTHCLEAR"

F_logout
