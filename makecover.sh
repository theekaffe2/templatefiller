#!/bin/bash
#set -v -x
set -e
compression=50
fps=15
noframes=7
posterlength=2
posterwidth=250
maxsize=5099999
input="$1"
numberregex='^[0-9]+$'

if [ -f "$input" ]; then
	length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")
	length=${length%.*}
else
	echo "Error"
	>&2 echo "Can't see the file: $input"
	exit 0
fi

if [[ $length =~ $numberregex ]]; then
if [ ! -d /tmp/grabs$length ]; then mkdir /tmp/grabs$length; fi 
if [ -f /tmp/grabs$length.txt ]; then rm /tmp/grabs$length.txt; fi

for ((n=1;n<noframes+1;n++)); do
	ffmpeg -v error -y -ss $(( length * n / (noframes+1) )) -t $posterlength -i "$1" -vf "fps=$fps,scale=$posterwidth:-1:flags=lanczos" /tmp/grabs$length/"$n.gif"
	echo "file /tmp/grabs$length/$n.gif" >> /tmp/grabs$length.txt
done

ffmpeg -hide_banner -loglevel quiet -y -f concat -safe 0 -r 15 -i "/tmp/grabs$length.txt"  -vf "fps=$fps" /tmp/$length.gif

size=$(stat -c%s "/tmp/$length.gif")
if [ "$size" -gt $maxsize ]&& command -v gifsicless &>/dev/null ; then
	gifsicle -b --lossy="$compression" /tmp/$length.gif
fi
if [ "$size" -gt $maxsize ]; then
	echo "Error"
	>&2 echo "Size of the gif exceeds the jerking limit of 5 mb."
fi

if [ -d /tmp/grabs$length ]; then rm -r /tmp/grabs$length; fi 

echo "/tmp/$length.gif"
exit 0

else
echo "Error"
>&2 echo "Can't read the duration of: $input"
exit 0

fi
