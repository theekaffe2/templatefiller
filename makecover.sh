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
output="/tmp/"

if [ -f "$input" ]; then
	length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")
	length=${length%.*}
else
	echo "Error"
	>&2 echo "Can't see the file: $input"
	exit 0
fi

if [[ $length =~ $numberregex ]]; then
if [ ! -d "$output"grabs$length ]; then mkdir "$output"grabs$length; fi 
if [ -f "$output"grabs$length.txt ]; then rm "$output"grabs$length.txt; fi

for ((n=1;n<noframes+1;n++)); do
	ffmpeg -v error -y -ss $(( length * n / (noframes+1) )) -t $posterlength -i "$1" -vf "fps=$fps,scale=$posterwidth:-1:flags=lanczos" "$output"grabs$length/"$n.gif"
	echo "file "$output"grabs$length/$n.gif" >> "$output"grabs$length.txt
done

ffmpeg -hide_banner -loglevel quiet -y -f concat -safe 0 -r $fps -i ""$output"grabs$length.txt"  -vf "fps=$fps" "$output"$length.gif

size=$(stat -c%s ""$output"$length.gif")
if [ "$size" -gt $maxsize ]&& command -v gifsicless &>/dev/null ; then
	gifsicle -b --lossy="$compression" "$output"$length.gif
fi
if [ "$size" -gt $maxsize ]; then
	echo "Error"
	>&2 echo "Size of the gif exceeds the jerking limit of 5 mb."
fi

if [ -d "$output"grabs$length ]; then rm -r "$output"grabs$length; fi 

echo ""$output"$length.gif"
exit 0

else
echo "Error"
>&2 echo "Can't read the duration of: $input"
exit 0

fi
