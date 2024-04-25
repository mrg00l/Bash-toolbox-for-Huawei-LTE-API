#!/bin/bash
rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/functions.bash"
source "$rundir/sms-commands.bash"

[[ $(F_checklogin) == "0" ]] && F_login

logger "New SMS received"

while [ "$(F_sms-count)" != "0" ]; do

	F_check-errors # We don't want there to be an error in the loop

	for sender in $(F_sms-list-contact); do

		F_check-errors # We don't want there to be an error in the loop
		
		F_sms-list-phone "$sender"
		
		[[ "$SENDER" == "$ADMINPHONE" || "$SENDER" == "$SATSMS" || "$SENDER" == "$CHECKINNUM" ]] && F_check_sms_cmd "$CONTENT" # Examination for an authorized command

		logger "SMSINDEX: $SMSINDEX Sender: $SENDER Text: $CONTENT Time: $SMSTIME"
		F_check_sms_checkin # "CheckIn" logic for numberless SAT messenger, won't do anything if YubiKey disabled.
        	F_telegram "SMS: $SENDER - $CONTENT - $SMSTIME" # Forward SMS to Telegram channel
		#F_sms-send "FWD SMS from $SENDER - $CONTENT" # Forward SMS to Admin phone
		# We don't want to pay for all the garbage, this is not a place to use channel F_satsms as destination, refer to numberless-satellite-messengers.txt
	        #F_email "SMSINDEX: $SMSINDEX Sender: $SENDER Text: $CONTENT Time: $SMSTIME" # Deprecated
		F_smsdelete "$SMSINDEX"
		sleep 1
	done

done

F_logout
