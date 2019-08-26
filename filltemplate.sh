#!/bin/bash
#set -v -x
folderwithimages=""
templatelocation=""
imageregex='.+\.(png|PNG|JPG|jpg|gif|GIF)'
Scriptfolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ "$#" -ne 0 ]; then
	>&2 echo -e "Usage is: $0"
	>&2 echo "Image folder is currrently set to $folderwithimages"
	>&2 echo "Template is set to $templatelocation"
	exit 1
fi

if [ -d "$folderwithimages" ]; then
	if [ ! "${folderwithimages: -1}" == "/" ]; then 
		folderwithimages="$folderwithimages/"
	fi
else
	echo "Coudln't identify as a directory: $folderwithimages"
fi

for file in "$folderwithimages"*; do
	if [[ "$file" =~ $imageregex ]]; then
		filename=$(basename "$file")
		echo "Uploading $filename"
		response=$(bash "$Scriptfolder/jerkuploader.sh" "$file")
		mediumlink='[url='$(echo "$response" | jq -r .image.url_viewer)'][img]'$(echo "$response" | jq -r '.image.file.resource.chain | .medium // .image' )'[/img][/url]'
		links+=("$mediumlink")
	fi
done
nooflinks="${#links[@]}"
for ((n=0;n<nooflinks;n++)); do
	if (( $n%2==0 )); then
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
if [ -f "$templatelocation" ]; then
	echo "Populating the template, and making new file called DoneTemplate.txt"
	awk -v TABLEIMAGES="$final" '{sub(/TABLEIMAGES/, TABLEIMAGES); print}' "$templatelocation" > "DoneTemplate.txt"
	else
	echo "No template. Writing the template to DoneTemplate.txt"
	echo "$final" > "DoneTemplate.txt"
fi
