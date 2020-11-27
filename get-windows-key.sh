#! /bin/bash

curl -s "https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys" | grep -B 1 "<h3 id=\|<td>.....-.....-.....-.....-.....</td>" | cut -d'>' -f 2 | cut -d'<' -f 1
