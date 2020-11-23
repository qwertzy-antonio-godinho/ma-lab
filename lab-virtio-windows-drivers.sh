#! /bin/bash

##
## Some versions of Windows (7 64 Bits) needs drivers or won't detect the Hard Disk,
## new versions are not signed by Microsoft and will fail installation
URL="https://fedorapeople.org/groups/virt/virtio-win/deprecated-isos/latest/virtio-win-0.1-100.iso"
OUTPUT_PATH="./media"
OUTPUT_VIRTIO_ISO="virtio-windows-drivers.iso"
OUTPUT_BOOTSTRAP_ISO="virtio-windows-bootstrap.iso"

function download_drivers () {
    printf " ---> Downloading Virtio drivers ISO ...\n"
    curl -L -S --progress-bar -C - "$URL" -o "$OUTPUT_PATH/$OUTPUT_VIRTIO_ISO"
    file -b "$OUTPUT_PATH/$OUTPUT_VIRTIO_ISO"
}

function make_bootstrap () {
	if [ -d "$OUTPUT_PATH/build" ]; then
    	rm -rf "$OUTPUT_PATH/build"
	fi
    printf " ---> Creating ISO $OUTPUT_BOOTSTRAP_ISO ...\n"
    if [ ! -d "$OUTPUT_PATH/build" ]; then
        mkdir "$OUTPUT_PATH/build"
    fi
    7z x "$OUTPUT_PATH/$OUTPUT_VIRTIO_ISO" -o"$OUTPUT_PATH/build" -y
    cp ./vm/vm-w7-64/autounattend.xml "$OUTPUT_PATH/build"
    mkisofs -m '.*' -J -r "$OUTPUT_PATH/build" > "$OUTPUT_PATH/$OUTPUT_BOOTSTRAP_ISO"
    file -b "$OUTPUT_PATH/$OUTPUT_BOOTSTRAP_ISO"
}



function main () {
	local value_action="$action"
	local value_parameters="$parameters"
    if [ ! -d "$OUTPUT_PATH" ]; then
        mkdir "$OUTPUT_PATH"
    fi
	case "$value_action" in
		"--download-drivers")
			download_drivers
		;;
		"--make-bootstrap")
			make_bootstrap
		;;
		*)
		printf "$0 - Option \"$value_action\" was not recognized...\n"
		printf "  --download-drivers : Download Windows Virtio drivers into $OUTPUT_PATH/$OUTPUT_VIRTIO_ISO\n"
		printf "  --make-bootstrap   : Creates an auxiliary bootstrap Windows ISO file in $OUTPUT_PATH/$OUTPUT_BOOTSTRAP_ISO\n"
		;;
	esac
}

action="$1"
parameters="${*: 2}"

main "$action" "$parameters"