#!/bin/bash
#
rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/functions.bash"

function rolling_wheel() {
	local chars='/-\|'
	while :; do
        	for (( i=0; i<${#chars}; i++ )); do
        		sleep 0.1
            		echo -en "\r${chars:$i:1}"
        	done
	done
	}

function prompt_yes_no() {
	read -p "$1" answer
    	if [[ ! $answer =~ ^[YyNn]$ ]]; then
        	echo "Invalid input. Please enter 'y' or 'n'."
        	return 1
    	fi
    	return 0
	}

echo

COUNTRY=$(curl -L -s ipinfo.io | grep country | cut -d '"' -f4)

prompt_yes_no "You have already edited the configuration file (y/n): " || exit 1
if [[ $answer =~ ^[Yy]$ ]]; then
	echo "Attempting to authorize with your LTE using the standard login function ..."
	
	rolling_wheel &
	wheel_pid=$!

	F_login &

	wait $!
	kill $wheel_pid &>/dev/null
	wait $wheel_pid 2>/dev/null
	echo -e "\rProcess finished"

	if [ $(F_checklogin) -eq 0 ] || [ -f "$DIR/error" ]; then
        	echo "Authorization Error."
		[ -f "$DIR/error" ] && echo "Error: $(cat $DIR/error | grep -oP '<code>\K[^<]*')" && \
                echo "You can try to find the error code in index.js or public.js or other *.js"
		echo "You only need to get one function to work - F_Login, these are just a few lines of Bash commands."
		LOGINSTD="0"
		sleep 2
	else
        	echo "You are logged in!"
		DEVMODEL=$(F_device-info)
		echo "Your device: $DEVMODEL"
		LOGINSTD="1"
		sleep 2 
	        F_logout
	fi

	prompt_yes_no "Do you want to try login using SCRAM (y/n): " || exit 1
	if [[ $answer =~ ^[Yy]$ ]]; then
		echo "Attempting to authorize with your LTE using the SCRAM login function ..."
       		
	       	rolling_wheel &
	        wheel_pid=$!	
	
		F_login-scram &

		wait $!
	        kill $wheel_pid &>/dev/null
        	wait $wheel_pid 2>/dev/null
	        echo -e "\rProcess finished"
		
		if [ $(F_checklogin) -eq 0 ] || [ -f "$DIR/error" ]; then
        		echo "Authorization Error."
			LOGINSCRAM="0"
			[ -f "$DIR/error" ] && echo "Error: $(cat $DIR/error | grep -oP '<code>\K[^<]*')" && \
			echo "You can try to find the error code in index.js or public.js or other *.js"
			echo
        	else
        		echo "You are logged in!"
            		echo "You can use Crypto functions."
			LOGINSCRAM="1"
            		echo
            		F_logout
        	fi
	fi

	prompt_yes_no "Send a test SMS message to the number $ADMINPHONE? (y/n): "
		if [[ $answer =~ ^[Yy]$ ]]; then
                echo "Sending a message, authorization..."

                rolling_wheel &
                wheel_pid=$!

                F_login &

                wait $!
                kill $wheel_pid &>/dev/null
                wait $wheel_pid 2>/dev/null
                echo -e "\rLogin process finished"
		sleep 1	
		F_sms-send "Test SMS. $(F_device-info) $COUNTRY"
		ERROR=$(echo "$response" | grep '<error>')
        	if [ "$ERROR" != "" ]; then
			SMS="error"
		else
			SMS=$(echo "$response" | grep -oP '<response>\K[^<]*')
		fi	
		echo "SMS sent to your LTE API, response: $SMS"
		echo
		F_logout
	fi
	
	echo
	echo "Can I use anonymized information about your device to improve compatibility in the future?"
	echo
	echo "Message: Hello from $COUNTRY! $DEVMODEL, login-std=$LOGINSTD, login-scram=$LOGINSCRAM, sms-send=$SMS, functions.bash version=$VERSION"
	echo "will be published anonymously in the Telegram channel: https://t.me/bash4lte_devices" 
	echo
	prompt_yes_no "(y/n): "
                if [[ $answer =~ ^[Yy]$ ]]; then
		echo
                echo "Thank You!..."
		# I don't make any income from this, that's why I use free hosting
		URL=$(dig +short TXT bash4lte.root.sx | tr -d '"')
		response=$(curl --connect-timeout 5 -k -L -X POST -d "device=$DEVMODEL&login-std=$LOGINSTD&login-scram=$LOGINSCRAM&sms-send=$SMS&country=$COUNTRY&version=$VERSION" $URL/post-deviceinfo.php)
		echo "Status: $response"
		echo
                echo "- Bye -"
		echo

	else
		echo
		echo "- Bye -"
		echo
	fi

else
    echo "Please edit configure.me first."
fi

