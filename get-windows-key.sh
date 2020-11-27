#! /bin/bash

curl -s "https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys" | grep -B 1 "<h3 id=\|<td>.....-.....-.....-.....-.....</td>" | sed -e 's/<\/table>\(.*\)$/\1/' -e 's/<td>\(.*\)$/\1/' -e 's/<\/td>\(.*\)$/\1/'
