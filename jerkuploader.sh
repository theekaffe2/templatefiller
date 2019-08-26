#!/bin/bash
#set -v -x
set -e
jerkcookie=""
## Check if 1 argument was given
if [ "$#" -ne 1 ]; then
	>&2 echo -e "Usage is: jerkuploader \e[3mfile\e[0m"
	exit 1
fi


#Either use existing cookie with login, or make a new one
if [ -f "$jerkcookie" ]; then
	cookie="-b $jerkcookie"
	else
	curl -c /tmp/jerkcookies.txt https://jerking.empornium.ph/ &> /dev/null
	cookie="-b /tmp/jerkcookies.txt"
	curl $cookie -c /tmp/jerkcookies.txt https://jerking.empornium.ph/?agree-consent &> /dev/null
fi

## Set Variables
File="$1"
Filename=$(basename "$File")
if $(echo "$1" | grep -q ","); then
	>&2 echo "Will have to remove commaes."
	OldFile="$File"
	File="/tmp/"$(echo "$Filename" | tr -d ",")
	mv "$OldFile" "$File"
	Filename=$(basename "$File")
fi
times=$(date +%s)
regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

## Set up session
curl $cookie https://jerking.empornium.ph/ -o /tmp/authjerk.txt &> /dev/null
auth=$(grep -m 1 "config.auth_token" /tmp/authjerk.txt | awk -F "\"" '{print $2}') 

## Upload picture
if [ -f "$File" ]; then
curl -w '%{http_code}\n' -L 'https://jerking.empornium.ph/json' \
$cookie \
-F "auth_token=$auth" \
-F "type=file" \
-F "action=upload" \
-F "timestamp=$times" \
-F "nsfw=0" \
-F "source=@$File;filename=$Filename" \
-o /tmp/jerktest.html &> /dev/null
elif [[ $File =~ $regex ]]; then
curl -w '%{http_code}\n' -L 'https://jerking.empornium.ph/json' \
$cookie \
-F "auth_token=$auth" \
-F "type=url" \
-F "action=upload" \
-F "timestamp=$times" \
-F "nsfw=0" \
-F "source=$File" \
-o /tmp/jerktest.html &> /dev/null
else
>&2 echo "Couldn't parse: $File"
if [ "$OldFile" ]; then mv "$File" "$OldFile"; fi
exit 1
fi

if [ "$OldFile" ]; then mv "$File" "$OldFile"; fi

## Check response
if grep -q \"code\":200 /tmp/jerktest.html; then
	link=$(cat /tmp/jerktest.html | jq -r '.')
	echo "$link"
else
	>&2 echo "Jerking threw an error."
	>&2 jq -r '.' /tmp/jerktest.html
	exit 1
fi
exit 0