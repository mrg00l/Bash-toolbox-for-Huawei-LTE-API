rundir="$(cd "$(dirname "$0")" && pwd)"
source "$rundir/configure.me"

# -------------------------- Messengers (channels) -----------------------------

F_telegram() {
	# Telegram Bot required, set TTOKEN and TCHATID in configure.me
	local MSG=$(F_convert-html "$1") 
	curl -s --data-urlencode "text=LTE_$MSG" "https://api.telegram.org/bot$TTOKEN/sendMessage?chat_id=$TCHATID" -o /dev/null
	}

F_sms-send() {
        SMSDATE=$(date +"%Y-%m-%d %H:%M:%S")
        XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Index>-1</Index><Phones><Phone>$ADMINPHONE</Phone></Phones><Sca></Sca><Content>$1</Content><Length>-1</Length><Reserved>0</Reserved><Date>$SMSDATE</Date></request>"
        response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/sms/send-sms")
        echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
        F_sms-cleanoutbox # I don't want to store any SMS in my LTE SMS outbox.
	}

F_satsms() {
	CONTENT="$1"
	CMDAUTH=$(echo "$CONTENT" | cut -d ' ' -f1 )
	F_check_sms_auth "$CMDAUTH"
        if [ "$AUTH" == "1" ] || [ "$SATUNSAFE" == "1" ] || [ -e "$DIR/reply.lic" ]; then
		logger "SATUNSAFE: $SATUNSAFE AUTH: $AUTH"
		if [ -e "$DIR/reply.lic" ]; then
    			logger "SAT reply licence exists, burning licence..."
			rm -f $DIR/reply.lic # burning license
		fi
                [ "$AUTH" == "1" ] && CONTENT=$(echo "$CONTENT" | sed "s/$CMDAUTH//g")
        	SMSDATE=$(date +"%Y-%m-%d %H:%M:%S")
	        XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Index>-1</Index><Phones><Phone>$SATSMS</Phone></Phones><Sca></Sca><Content>$CONTENT</Content><Length>-1</Length><Reserved>0</Reserved><Date>$SMSDATE</Date></request>"
	        response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/sms/send-sms")
        	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
		F_sms-cleanoutbox # I don't want save any SMS in my LTE SMS outbox
		logger "F_satsms: $CONTENT"
	else
                CONTENT="(SAT-Auth-Fail) $CONTENT"
		logger "$CONTENT"
        fi
	}


F_email() {
	# Deprecated.
	#echo "$1" | mail -s "SMS from LTE" $ADMINMAIL
	return
	}

F_ms_teams() {
	# Do it yourself if you need it, try asking Google "Teams Webhook"
	logger "No, I don't need integration with Teams :)"
	return
	}

# --- Helpers ---

F-lte-month-stats() {
	response=$(curl -k -s -i -b $DIR/cookie -H "__RequestVerificationToken:$(cat $DIR/token)" $URL/api/monitoring/month_statistics)
	MONTHDOWN=$(echo "$response" | grep -oP '<CurrentMonthDownload>\K[^<]*')
	MONTHUP=$(echo "$response" | grep -oP '<CurrentMonthUpload>\K[^<]*')
	MONTHCLEAR=$(echo "$response" | grep -oP '<MonthLastClearTime>\K[^<]*')
	}

F_set-net-mode() {
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><NetworkMode>03</NetworkMode><NetworkBand>3FFFFFFF</NetworkBand><LTEBand>$1</LTEBand></request>"
	response=$(curl -k -s -i -b $DIR/cookie -X POST -H "__RequestVerificationToken:$(cat $DIR/token)" -d "$XML" $URL/api/net/net-mode)
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	}

F_get-net-mode() {
	response=$(curl -k -s -i -b $DIR/cookie -H "__RequestVerificationToken:$(cat $DIR/token)" $URL/api/net/net-mode)
	echo "$response" | grep -oP '<LTEBand>\K[^<]*'
	}

F_lte-reboot() {
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Control>1</Control></request>"
	response=$(curl -k -s -i -b $DIR/cookie -X POST -H "__RequestVerificationToken:$(cat $DIR/token)" -d "$XML" $URL/api/device/control)
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
        local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
}

F_uptime() {
	echo "$(curl -k -s -b "$DIR/cookie" "$URL/api/device/information" | grep -oP '<uptime>\K[^<]*')"
	}

F_sms-cleanoutbox() {
	# Delete all SMS stored in outbox
	for smsid in $(F_smsoutboxid); do
        F_smsdelete "$smsid"
	done
	}

F_sms-list-phone() {
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><phone>$1</phone><pageindex>1</pageindex><readcount>1</readcount><nonce>$SERVERNOUNCE</nonce></request>"
        response=$(curl -k -s -i -b $DIR/cookie -X POST -H "__RequestVerificationToken:$(cat $DIR/token)" -d "$XML" $URL/api/sms/sms-list-phone)
        echo "$response" |grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
        SMSINDEX=$(echo "$response" | grep -oP '<index>\K[^<]*')
        SENDER=$(echo "$response" | grep -oP '<phone>\K[^<]*')
        CONTENT=$(echo "$response" | grep -oP '<content>\K[^<]*')
        SMSTIME=$(echo "$response" | grep -oP '<date>\K[^<]*')
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	}

F_smsoutboxid() {
	# BoxType 2 = outbox, return SMS ID list, stored in outbox
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><PageIndex>1</PageIndex><ReadCount>20</ReadCount><BoxType>2</BoxType><SortType>0</SortType><Ascending>0</Ascending><UnreadPreferred>0</UnreadPreferred></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/sms/sms-list")
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
	echo "$response" | grep -oP '<Index>\K[^<]*'
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	}

F_smsdelete() {
	# Delete SMS by SMS ID
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Index>$1</Index></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/sms/delete-sms")
	TOKEN=$(echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g')
	echo "$TOKEN" > $DIR/token
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	}

F_check_sms_cmd () {
	# If authorized, will run any function / Bash command. For example F_SMSCMD-lte-uptime, text "mypassword lte uptime". No output (use output in Your function).
	# For YubiKey OTP text generated OTP and command "vncecbardhflvnunggrdcedlhkbceenvlbhuikcbufll lte uptime"
    	[ "$1" == "" ] && return
	CMDAUTH=$(echo "$1" | cut -d ' ' -f1 )
    	CMDTYPE=$(echo "$1" | cut -d ' ' -f2 )
    	CMDRUN=$(echo "$1" | cut -d ' ' -f3 )
	F_check_sms_auth "$CMDAUTH"
	if [ "$AUTH" == "1" ]; then
	 	logger "runnung F_SMSCMD-$CMDTYPE-$CMDRUN"
		CONTENT=$(echo "$CONTENT" | sed "s/$CMDAUTH//g")
		F_SMSCMD-$CMDTYPE-$CMDRUN
		if [ "$SENDER" == "$CHECKINNUM" ] && [ "$CHECKINNUM" != "$SATSMS" ]; then
			logger "Authorized request to change SATSMS number to: $SENDER"
			sed -i "s/SATSMS=\"$SATSMS\"/SATSMS=\"$SENDER\"/g" $rundir/configure.me
		fi
	else
		logger "SMS CMD auth error"
		CONTENT="(CMD-Auth-Fail) $CONTENT"
	fi
	}

F_check_sms_auth() {
	AUTH="0"
	if [ "$YUBIKEY_ENABLED" == "1" ]; then
		response=$(curl -k -s "$YUBIKEYURL?otp=$1")
		local TESTOTP=$(echo "$response" | grep "status=OK")
		logger "OTP: $TESTOTP Key: $1"
		[ "$TESTOTP" != "" ] && touch $DIR/reply.lic && AUTH="1" # issuing a SAT license to reply
	else
		local TESTPASS=$(echo "$1"| grep "^$SMSPWD")
		logger "Pass auth: $TESTPASS"
		[ "$TESTPASS" != "" ] && AUTH="1"
	fi
	}

F_check_sms_checkin() {
	[ "$YUBIKEY_ENABLED" != "1" ] && return
	TESTCHECKIN=$(echo "$CONTENT" | grep "$CHECKIN")
	if [ "$TESTCHECKIN" == "" ]; then
		return
	else
		if [ "$CHECKINNUM" != "$SENDER" ]; then
			logger "Check-In number changed"
			sed -i "s/CHECKINNUM=\"$CHECKINNUM\"/CHECKINNUM=\"$SENDER\"/g" $rundir/configure.me
			F_telegram "Check-In number changed to $SENDER"
		else
			logger "Check-In recived, number not changed"
		fi
		return
	fi
	}

F_sms-count() {
	SMSCOUNT=$(curl -k -s -b "$DIR/cookie" "$URL"/api/sms/sms-count | grep -oP '<LocalInbox>\K[^<]*')
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	echo "$SMSCOUNT"
	}

F_sms-contact-count() {
	SMSCCOUNT=$(curl -k -s -b "$DIR/cookie" "$URL"/api/sms/sms-count-contact | grep -oP '<count>\K[^<]*')
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	[ "$SMSCCOUNT" != "" ] && echo "0" || echo "$SMSCCOUNT"
	}

F_sms-list-contact() {
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><pageindex>1</pageindex><readcount>20</readcount><nonce>$SERVERNOUNCE</nonce></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/sms/sms-list-contact")
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
	CONTACTS=$(echo "$response" | grep -oP '<phone>\K[^<]*')
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	echo "$CONTACTS"
	}

F_sms-get() {
	# Only for "old style" firmware with api/sms/sms-list
	XML="<?xml version: \"1.0\" encoding=\"UTF-8\"?><request><PageIndex>1</PageIndex><ReadCount>20</ReadCount><BoxType>1</BoxType><SortType>0</SortType><Ascending>0</Ascending><UnreadPreferred>0</UnreadPreferred></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/sms/sms-list")
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
	local ERROR=$(echo "$response" | grep '<error>')
	[ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	SMSXML=$(echo "$response" | grep "<" )
	}

F_mobile-dataswitch() {
	# 0 = disconnect internet; 1 = connect internet
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><dataswitch>$1</dataswitch></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/dialup/mobile-dataswitch")
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > $DIR/token
	local ERROR=$(echo "$response" | grep '<error>')
        [ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	logger "mobile-dataswitch $1"
	}

F_device-info() {
	response=$(curl -k -s -i -b $DIR/cookie -H "__RequestVerificationToken:$(cat $DIR/token)" $URL/api/device/information)
	local MSG="$(echo "$response" | grep -oP '<ProductFamily>\K[^<]*')"
	local MSG="$MSG $(echo "$response" | grep -oP '<Classify>\K[^<]*')"
	local MSG="$MSG $(echo "$response" | grep -oP '<DeviceName>\K[^<]*')"
	local MSG="$MSG $(echo "$response" | grep -oP '<SoftwareVersion>\K[^<]*')"
	echo "$MSG"
	}
	

F_checklogin() {
        # Return 1 if logged in, else 0
        if [[ "$(curl -k -s -b "$DIR/cookie" "$URL/api/user/state-login" | grep -oP '<Username>\K[^<]*')" == "" ]]; then
                echo "0"
        else
                echo "1"
        fi
	}

F_convert-html() {
        # If something is missing, add it yourself:
        # https://www.ee.ucl.ac.uk/~mflanaga/java/HTMLandASCIItableC1.html
        local input="$1"
        local input=$(echo "$input" | sed -E 's/&apos;/'"'"'/g')
        local input=$(echo "$input" | sed -E 's/&quot;/"/g')
        local input=$(echo "$input" | sed -E 's/&gt;/>/g')
        local input=$(echo "$input" | sed -E 's/&lt;/</g')
        local input=$(echo "$input" | sed -E 's/&amp;/\&/g')
        local input=$(echo "$input" | sed -E 's/&#x2F;/\//g')
        local input=$(echo "$input" | sed -E 's/&#x2D;/\-/g')
        local input=$(echo "$input" | sed -E 's/&#x3A;/\:/g')
	local input=$(echo "$input" | sed -E 's/&#x3B;/\;/g')
	local input=$(echo "$input" | sed -E 's/&#40;/\(/g')
	local input=$(echo "$input" | sed -E 's/&#41;/\)/g')
	echo "$input"
	}

F_convert-bytes() {
	local bytes=$1
	local units=('B' 'KB' 'MB' 'GB' 'TB')
	local unit=0

	while ((bytes > 1024 && unit < ${#units[@]}-1)); do
        ((bytes /= 1024))
        ((unit++))
    	done

    	echo "$bytes ${units[unit]}"
	}

F_convert-seconds() {
	local seconds=$1
	local days=$((seconds / 86400))
	local seconds=$((seconds % 86400))
	local hours=$((seconds / 3600))
	local seconds=$((seconds % 3600))
	local minutes=$((seconds / 60))
	local seconds=$((seconds % 60))
	echo "$days d. $hours h. $minutes min. $seconds sec."
	}

F_check-errors() {
	# If any error exist, log and exit

	echo $(date) > "$DIR/write.test" || {
    	echo "Can't write to tmp directory $DIR" 
    	logger "Can't write to tmp directory $DIR"
    	exit 1
	}

	if [ -e "$DIR/error" ]; then
		ERROR=$(cat "$DIR/error" | grep -oP '<code>\K[^<]*')
		echo "ERROR: $ERROR"
		logger "ERROR: $ERROR"
		exit 1
	fi

	if [ "$(cat $DIR/token)" == "" ]; then
		logger "ERROR: Token empty"
		echo "ERROR: Token empty"
		exit 1
	fi
	}

F_RSAENC() {
# I don't know why you would need a Huawey RSA public key in PEM format.
# Everything works just fine without encryption after calling SCRAM with my device.
# I'll just leave this here as template.
	local publicKey_rsapadingtype="1" # May be 0 in You environment
	local encstring="$1"
	local EXP=""
	local MOD=""
	local rsa
	local encStr
	local num
	local restotal

	if [ "$encstring" == "" ]; then
        	return
    	fi
	response=$(curl -k -s -b "$DIR/cookie" "$URL/api/webserver/publickey")
	EXP=$(echo "$response" | grep "encpubkey" | grep -oP '<encpubkeye>\K[^<]*')
	MOD=$(echo "$response" | grep "encpubkey" | grep -oP '<encpubkeyn>\K[^<]*')
	echo -e "asn1=SEQUENCE:pubkeyinfo\n\n[pubkeyinfo]\nalgorithm=SEQUENCE:rsa_alg\npubkey=BITWRAP,SEQUENCE:rsapubkey\n\n[rsa_alg]\nalgorithm=OID:rsaEncryption\nparameter=NULL" > $DIR/def.asn1
	echo -e "[rsapubkey]\nn=INTEGER:0x$MOD" >> $DIR/def.asn1
	echo "e=INTEGER:0x$EXP" >> $DIR/def.asn1
	openssl asn1parse -genconf $DIR/def.asn1 -out $DIR/pubkey.der -noout
	openssl rsa -in $DIR/pubkey.der -inform der -pubin -out $DIR/pubkey.pem 2>/dev/null
	rsa=$(cat $DIR/pubkey.pem)
	echo "$rsa" > $rundir/pubkey.pem
	encStr=$(echo -n "$encstring" | base64)
	echo -n "$encStr" > $DIR/encstr.txt
	if [ "$publicKey_rsapadingtype" = "1" ]; then
        	num="214"
    	else
        	num="245"
    	fi

 	restotal=""
	encdata="0"
    	for ((i = 0; ${#encdata} > 0; i+=$num)); do
        encdata=$(dd if=$DIR/encstr.txt bs=1 skip=$i count=$num status=none) # Ugly, but just for testing.
	if [ "$encdata" != "" ]; then
          res=$(echo -n "$encdata" | openssl rsautl -encrypt -oaep -pubin -inkey <(echo "$rsa") | base64)
	  restotal+="$res"
        fi
	done
	echo -n "TST: $restotal"
	}

# --- Core ----

F_login-scram() {
	# Salted Challenge Response Authentication Mechanism, CryptoJS.SCRAM emulation.
	# (and new HMAC-H(?) o_O by Huawei implementation)

	[ -d "$DIR" ] && rm -rf "$DIR" # Start from scratch
	mkdir -p "$DIR"
	response=$(curl -k -s -c "$DIR/cookie" "$URL/html/index.html")
	KEY=$(echo -n "$PASS" | sha256sum | cut -d ' ' -f1 | tr -d "\n" | base64 -w 0)
	WSTOKEN=$(curl -k -s -b "$DIR/cookie" "$URL/api/webserver/token" | grep -oP '<token>\K[^<]*')
	TOKEN=$(echo "$WSTOKEN" | cut -c 33-)
	FIRSTNONCE=$(echo -n "$USER$KEY" | sha256sum | cut -d ' ' -f1 | tr -d "\n")
	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><username>$USER</username><firstnonce>$FIRSTNONCE</firstnonce><mode>1</mode></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$TOKEN" -d "$XML" "$URL/api/user/challenge_login")
	echo "$response" | grep "Token:" | cut -d ":" -f2 | sed 's/[^[:alnum:]]//g' > "$DIR/token"
	ITERATIONS=$(echo "$response" | grep -oP '<iterations>\K[^<]*')
	SALT=$(echo "$response" | grep -oP '<salt>\K[^<]*')
	SERVERNONCE=$(echo "$response" | grep -oP '<servernonce>\K[^<]*')
	AUTHMSG="$FIRSTNONCE,$SERVERNONCE,$SERVERNONCE"
	
	[ "$SALT" == "" ] && echo "<code>SCRAM not supported</code>" > $DIR/error  && return
	
	# If You don't like Python, feel free to replace it with any other tool, Nettle, Openssl, or any other. I don't like many dependencies, this is why Python selected.
	# Variables starting with "_", like _SPWD, can be generated only once (until password/firmware/... will not be changed), You can do it even on external systems
	# like Windows (lol), then put this variable in configure.me and comment here. Who knows, maybe you have plans to use this code on Your IoT Toaster :D
	_SPWD=$(python -c "import hashlib, binascii; print(binascii.hexlify(hashlib.pbkdf2_hmac('sha256', b'$PASS', bytes.fromhex('$SALT'), $ITERATIONS, 32)).decode('utf-8'))") 2> /dev/null
	# Less code but +1 dependency: echo -n "$PASS" | nettle-pbkdf2 --length=32 --iterations=$ITERATIONS --hex-salt $SALT | tr -d " "
	_CLIENTKEY=$(python -c "import hmac; a = bytes('Client Key', 'utf-8'); b = bytes.fromhex('$_SPWD'); print(hmac.new(a, b, 'sha256').hexdigest())") # o_O Yes they did it! :D
	_STOREDKEY=$(python -c "import hashlib; a = bytes.fromhex('$_CLIENTKEY'); hasher = hashlib.sha256(); hasher.update(a); print(hasher.hexdigest())")
	CSIG=$(python -c "import hmac; a = bytes('$AUTHMSG', 'utf-8'); b = bytes.fromhex('$_STOREDKEY'); print(hmac.new(a, b, 'sha256').hexdigest())") # HMAC-H by Huawei :D
	CPROOF=$(python -c "a = bytes.fromhex('$_CLIENTKEY'); b = bytes.fromhex('$CSIG'); print(''.join(format(a ^ b, '02x') for a, b in zip(a, b)))")
	# Same with Bash hardcore: a=$(echo "$_CLIENTKEY" | xxd -r -p); b=$(echo "$CSIG" | xxd -r -p); result=""; for ((i = 0; i < ${#a}; i++)); do xor=$(( $(printf "%d" "'${a:$i:1}") \
	# ^ $(printf "%d" "'${b:$i:1}") )); result+=$(printf "%02x" $xor); done; -> This is the reason why you can find several Python lines here :D

	XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><clientproof>$CPROOF</clientproof><finalnonce>$SERVERNONCE</finalnonce></request>"
	response=$(curl -k -s -i -b "$DIR/cookie" -c "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/user/authentication_login")
	echo "$response" | grep "Token:" | cut -d "#" -f3 | sed 's/[^[:alnum:]]//g' > $DIR/token
	SRVSIGNATURE=$(echo "$response" | grep -oP '<serversignature>\K[^<]*')
	RSAPUB=$(echo $response | grep -oP '<rsapubkeysignature>\K[^<]*')
	RSAN=$(echo $response | grep -oP '<rsan>\K[^<]*')
	RSAE=$(echo $response | grep -oP '<rsae>\K[^<:]*')
	local ERROR=$(echo "$response" | grep '<error>')
	[ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error
	}

F_login() {
	# No support for crypto functions.
	[ -d "$DIR" ] && rm -rf "$DIR" # Start from scratch
        mkdir -p "$DIR" || echo "Can't create $DIR" || exit 1
        TOKEN=$(curl -k -s -c "$DIR/cookie" "$URL/html/index.html" | grep csrf_token | tail -n 1 | cut -d '"' -f 4)
        KEY=$(echo -n "$PASS" | sha256sum | cut -d ' ' -f1 | tr -d "\n" | base64 -w 0)
        FIRSTNONCE=$(echo -n "$USER$KEY$TOKEN" | sha256sum | cut -d ' ' -f1 | tr -d "\n" | base64 -w 0)
        XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Username>$USER</Username><Password>$FIRSTNONCE</Password><password_type>4</password_type></request>"
        response=$(curl -k -s -i -b "$DIR/cookie" -c "$DIR/cookie" -X POST -H "__RequestVerificationToken:$TOKEN" -d "$XML" "$URL/api/user/login")
        echo "$response" | grep "Token:" | cut -d "#" -f3 | sed 's/[^[:alnum:]]//g' > $DIR/token
	local ERROR=$(echo "$response" | grep '<error>')
	[ "$ERROR" != "" ] && echo "$ERROR" > $DIR/error && logger "Login error detected"
	}

F_logout() {
        # We don't need grep updated RequestVerificationToken here :) No input and output.
        XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Logout>1</Logout></request>"
        response=$(curl -k -s -b "$DIR/cookie" -X POST -H "__RequestVerificationToken:$(cat "$DIR/token")" -d "$XML" "$URL/api/user/logout")
	[ -d "$DIR" ] && rm -rf "$DIR"
        #echo "$response" # But uncomment this line to see output XML if You need it.
	}

# functions.bash version information for analytics
VERSION="1.2"
