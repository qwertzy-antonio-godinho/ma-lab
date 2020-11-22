#! /bin/bash

URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
OUTPUT_PATH="./media"
OUTPUT_NAME="virtio-win.iso"

printf " ---> Downloading latest virtio-win.iso to $OUTPUT_PATH ...\n"
curl -L -S --progress-bar -C - "$URL" -o "$OUTPUT_PATH/$OUTPUT_NAME"
file -b "$OUTPUT_PATH/$OUTPUT_NAME"
