#!/bin/bash
# 
rundir="$(cd "$(dirname "$0")" && pwd)" # Replace these two lines with a static path if you wish.
source "$rundir/functions.bash" # Example: source "/home/lte/functions.bash"
F_login # No needs to login just for Telegram messaging, but must be logged in for LTE operations, like SMS sending or LTE band settings
#[[ $(F_checklogin) == "0" ]] && F_login # or check login status and use F_login only if You logged out
#--------------Any Bash commands after this line-----------------


F_telegram "My cool message to Telegram" # MSG to Telegram

F_sms-send "My cool SMS from LTE" # SMS to Admin phone

#F_satsms "cccjgjgkhcbbirdrfdnlnghhfgrtnnlgedjlftrbdeut test message" # Authorized SMS message to satellite communicator
#
# You can't output something from Your script, through this SAT interface without valid OTP, only one way - uncoment SATUNSAFE before F_satsms 
#SATUNSAFE="1" # If set to 1, will send messages without authorization, You will pay for all the spam and You could lose all your money.
#F_satsms "Don't do this. You have been warned."
#SATUNSAFE="0" # turn off unsafe mode.

# But each OTP (not password) authorized SMS command issue licence for 1 reply from Your script to satellite communicator without changing unsafe mode.
# F_satsms "I am sending a response to the command you authorized with OTP" # - will work.
# F_satsms "By mistake I am sending again a response to the command you authorized with OTP" # - will not work, the reply license has been used before.

#------------- The next line is optional, but ... ----------------
F_logout # ... it's good manners to say goodby and clean up after yourself


# Example: send message to Telegram, but if no internet connection, send it to Admin by SMS 
#
#MESSAGE="Hello."
#
#ping -c 3 8.8.8.8 > /dev/null
#if [ $? -eq 0 ]; then
#        logger "LTE online, sending to Telegram"
#	 F_telegram "$MESSAGE"
#else
#        logger "LTE offline, MSG to SMS and reboot router."
#	 F_sms-send "$MESSAGE btw I will reboot Your router :)"
#        ssh user@myrouter reboot 2> /dev/null
#fi
