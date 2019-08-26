#!/bin/bash
#set -v -x
set -e
folderwithimages=""
templatelocation=""
Output=""

imageregex='.+\.(png|PNG|JPG|jpg|gif|GIF)'
videoregex='.+\.(mp4|MP4|mov|MOV|mkv|MKV)'
Scriptfolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "$templatelocation" ]; then
	templatelocation="$Scriptfolder/template.txt"
fi

if [ "$#" -gt 1 ]; then
	>&2 echo -e "Usage is: $0 (Folder)"
	>&2 echo "Image folder is currrently set to $folderwithimages"
	>&2 echo "Template is set to $templatelocation"
	exit 1
fi

if [ "$1" ]; then
	folderwithimages="$1"
fi

if [ -d "$folderwithimages" ] || [ -z "$folderwithimages" ]; then
	if [ -d "$folderwithimages" ] && [ ! "${folderwithimages: -1}" == "/" ]; then 
		folderwithimages="$folderwithimages/"
	fi
else
	echo "Couldn't identify input as a directory: $folderwithimages"
	exit 1
fi
if [ -d "$Output" ] || [ -z "$Output" ]; then
	if [ -d "$Output" ] && [ ! "${Output: -1}" == "/" ]; then 
		Output="$Output/"
	fi
else
	echo "Couldn't identify output as a directory: $Output"
	exit 1
fi

imageup ()
{
filename=$(basename "$1")
echo "Uploading $filename"
response=$(cat /tmp/jerktest.html )
#response=$(bash "$Scriptfolder/jerkuploader.sh" "$1")
mediumlink='[url='$(echo "$response" | jq -r .image.url_viewer)'][img]'$(echo "$response" | jq -r '.image.file.resource.chain | .medium // .image' )'[/img][/url]'
links+=("$mediumlink")
}
makethumbs ()
{
filename=$(basename "$1")
endlocaton="$Output$filename.jpg"
echo "Making thumbs and uploading thumbs for $filename"
#if [ ! -f "$endlocaton".jpg ]; then vcs -q -n 21 -o "$endlocaton".jpg "$1" &> /dev/null; fi
response=$(cat /tmp/jerktest.html)
#response=$(bash "$Scriptfolder/jerkuploader.sh" "$endlocaton".jpg)
vcslink+=($(echo "$response" | jq -r .image.file.resource.chain.image))
}


for file in "$folderwithimages"*; do
	if [[ "$file" =~ $imageregex ]]; then
		imageup "$file"
	elif [[ "$file" =~ $videoregex ]] && command -v vcs &>/dev/null; then
		makethumbs "$file"
	fi
done
nooflinks="${#links[@]}"


if [ "$nooflinks" -gt 0 ]; then
for ((n=0;n<nooflinks;n++)); do
	if (( n%2==0 )); then
		if [ "${links[n+1]}" ]; then
			final="$final"'[tr]
[td]'"${links[n]}"'[/td]
[td]'"${links[n+1]}"'[/td]
[/tr]'
		else
			final="$final"'[tr]
[td]'"${links[n]}"'[/td]
[/tr]'
		fi
	fi
done
final='[table=center,50%,nball]
'"$final"'
[/table]'
fi

nooflinks="${#vcslink[@]}"

if [ "$nooflinks" -gt 0 ]; then
for ((n=1;n<=nooflinks;n++)); do
if [ -f "$templatelocation" ]; then
	echo "Populating the template, and making new file called $n.txt"
	awk -v TABLEIMAGES="$final" -v CONTACTSHEET="${vcslink[$n]}" '{sub(/TABLEIMAGES/, TABLEIMAGES); sub(/CONTACTSHEET/, CONTACTSHEET); print}' "$templatelocation" > "$Output$n.txt"
	else
	echo "No template. Writing the Output to $n.txt"
	echo "$final" > "$Output$n.txt"
fi
done
else
if [ -f "$templatelocation" ]; then
	echo "Populating the template, and making new file called 1.txt"
	awk -v TABLEIMAGES="$final" '{sub(/TABLEIMAGES/, TABLEIMAGES); print}' "$templatelocation" > "$Output""1.txt"
	else
	echo "No template. Writing the Output to 1.txt"
	echo "$final" > "$Output""1.txt"
fi
fi
exit 0