#!/bin/bash
#
rundir="$(cd "$(dirname "$0")" && pwd)" # Replace these two lines with a static path if you wish.
source "$rundir/functions.bash" # Example: source "/home/lte/functions.bash"

F_login

echo "Parsing any API by custom request:"
echo

response=$(curl -k -s -i -b $DIR/cookie $URL/api/device/signal)
TOWER=$(echo "$response" | grep -oP '<enodeb_id>\K[^<]*')
CELL=$(echo "$response" | grep -oP '<cell_id>\K[^<]*')
BAND=$(echo "$response" | grep -oP '<band>\K[^<]*')
SNR=$(echo "$response" | grep -oP '<sinr>\K[^<]*')
ULBW=$(echo "$response" | grep -oP '<ulbandwidth>\K[^<]*')
DLBW=$(echo "$response" | grep -oP '<dlbandwidth>\K[^<]*')

echo "TOWER: $TOWER"
echo "CELL: $CELL"
echo "BAND: $BAND"
echo "SNR: $SNR"
echo "ULBW: $ULBW"
echo "DLBW: $DLBW"

echo
echo "or using functions.bash"
echo
echo "Current month data usage:"
        F-lte-month-stats
	echo "Download: $MONTHDOWN"
	echo "Upload: $MONTHUP"
	echo "Total: $(F_convert-bytes $((MONTHUP + MONTHDOWN)))"
	echo "Last cleared: $MONTHCLEAR"


F_logout
