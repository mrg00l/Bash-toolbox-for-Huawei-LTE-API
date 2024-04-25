# --- SMS Commands allowed ---
# Try create You own commands, it's simple. Good start for example -
# update ADMINPHONE in configure.me using SED (or any other).

F_SMSCMD-rpi-uptime() {
        # Telegram message with localhost (not LTE) uptime in human readable format
	# SMS request example "pass rpi uptime"
        local MSG=$(uptime -p)
        F_telegram "RPI $MSG"
	}

F_SMSCMD-rpi-reboot() {
	# We can't run this directly, it may disrupt other SMS processes
	# SMS request example "pass rpi reboot"
	logger "SMS rpi reboot"
	F_telegram "RPI reboot requested"
	$rundir/cmd-run-this-later.sh "sudo reboot" &
	}

F_SMSCMD-lte-uptime() {
	# SMS request example "pass lte uptime"
        local UT="$(F_uptime)"
	local MSG="LTE uptime: $(F_convert-seconds $UT)"
        F_telegram "$MSG"
	#F_satsms "$MSG"
	}

F_SMSCMD-lte-allband() {
	# We can't run this directly, it may disrupt other SMS processes
	# SMS request example "pass lte allband"
	$rundir/cmd-run-this-later.sh "F_set-net-mode 7FFFFFFFFFFFFFFF" &
	}

F_SMSCMD-lte-off() {
	# We can't run this directly, it may disrupt other SMS processes
	# SMS request example "pass lte off"
	logger "SMS mobile data off"
	F_telegram "Mobile data OFF requested"
	$rundir/cmd-run-this-later.sh "F_mobile-dataswitch 0" &
	logger "runnung in background: lte off"
	}

F_SMSCMD-lte-on() {
	# SMS request example "pass lte on"
	# We can't run this directly, it may disrupt other processes
	# We can't send Telegram msg without data connection, connection will take some time
	logger "SMS mobile data on" # But we can log request, or send SMS with F_sms-send
	$rundir/cmd-run-this-later.sh "F_mobile-dataswitch 1" &
	}

F_SMSCMD-lte-reboot() {
	# We can't run this directly, it may disrupt other processes
	# SMS request example "pass lte reboot"
	logger "SMS lte reboot"
	F_telegram "LTE reboot requested"
	$rundir/cmd-run-this-later.sh "F_lte-reboot" &
	}

F_SMSCMD-lte-stats() {
	# Current month data usage
	# SMS request example "pass lte stats"
	F-lte-month-stats
	MONTHTOTAL=$((MONTHUP + MONTHDOWN))
	F_telegram "LTE current month data usage: $(F_convert-bytes $MONTHTOTAL) Last cleared: $MONTHCLEAR"
	}

F_SMSCMD-sat-uptime-all() {
	# Send uptime to SAT messenger
        # SMS request example "vncecbardhflvnunggrdcedlhkbceenvlbhuikcbufll sat uptime-all"
	local LTEUT="$(F_uptime)"
        CONTENT="RPI uptime: $(uptime -p) LTE uptime: $(F_convert-seconds $LTEUT)"
	F_satsms "$CONTENT" # One SAT reply allowed with OTP
	F_satsms "Second try: $CONTENT" # this should not be sent, but no one is safe from mistakes.
	}

F_SMSCMD-apc-reboot-2() {
	# Reboot UPS port 2
	# SMS request example "pass apc reboot-2"
	/home/pi/scripts/apc_ups.sh "reboot" "2" &
	}

F_SMSCMD-router-reboot() {
	# We can't run this directly, it may disrupt other processes
	$rundir/cmd-run-this-later.sh "ssh router reboot"
	}
# Add yours as you like ...

