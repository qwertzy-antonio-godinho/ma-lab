#! /bin/bash

URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
OUTPUT_PATH="./media"
OUTPUT_VIRTIO_ISO="virtio-windows-drivers.iso"
OUTPUT_BOOTSTRAP_ISO="virtio-windows-bootstrap.iso"

function download_drivers () {
    printf " ---> Downloading latest Virtio ISO ...\n"
    curl -L -S --progress-bar -C - "$URL" -o "$OUTPUT_PATH/$OUTPUT_VIRTIO_ISO"
    file -b "$OUTPUT_PATH/$OUTPUT_VIRTIO_ISO"
}

function make_bootstrap () {
    printf " ---> Creating ISO $OUTPUT_BOOTSTRAP_ISO ...\n"
    if [ ! -d "$OUTPUT_PATH/build" ]; then
        mkdir "$OUTPUT_PATH/build"
    fi
    7z x "$OUTPUT_PATH/$OUTPUT_VIRTIO_ISO" -o"$OUTPUT_PATH/build" -y
    # TODO: Rework this
    cp ./vm/vm-w7-64/autounattend.xml "$OUTPUT_PATH/build"
    # ----
    mkisofs -m '.*' -J -r "$OUTPUT_PATH/build" > "$OUTPUT_PATH/$OUTPUT_BOOTSTRAP_ISO"
    file -b "$OUTPUT_PATH/$OUTPUT_BOOTSTRAP_ISO"
}

function clean_build () {
    printf " ---> Removing $OUTPUT_PATH/build ...\n"
    rm -rf "$OUTPUT_PATH/build"
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
		"--clean-build")
			clean_build
		;;
		*)
		printf "$0 - Option \"$value_action\" was not recognized...\n"
		printf "  --download-drivers : Download latest Windows virtio drivers into $OUTPUT_PATH/$OUTPUT_VIRTIO_ISO\n"
		printf "  --make-bootstrap   : Creates an auxiliary bootstrap Windows ISO file in $OUTPUT_PATH/$OUTPUT_BOOTSTRAP_ISO\n"
		printf "  --clean-build      : Removes directory $OUTPUT_PATH/build\n"
		;;
	esac
}

action="$1"
parameters="${*: 2}"

main "$action" "$parameters"