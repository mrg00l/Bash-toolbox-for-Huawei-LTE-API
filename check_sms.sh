#!/bin/bash
#
# We don't need to login to your Huawei device to check new messages.
# If we received a new message, run script X.

rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/configure.me"
# 
nomsg=$(curl -k -s $URL/api/monitoring/check-notifications | grep "<UnreadMessage>0</UnreadMessage>")
if [ -z "$nomsg" ]; then
		# Script "X"
		/home/pi/dev/sms-inbox-handler.sh
fi
