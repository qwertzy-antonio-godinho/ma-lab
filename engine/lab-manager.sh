#! /bin/bash

# Paths
# ------------------------------
VAR_IMAGES="$ENGINE/$VM_NAME/iso"
VAR_BUILD="$ENGINE/$VM_NAME/build"
VAR_DATA="$ENGINE/$VM_NAME/data"

# Screen functions
# ------------------------------
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
BLUE=$(tput setaf 6)
WHITE=$(tput setaf 7)
GRAY=$(tput setaf 8)
NC=$(tput sgr0) # No colour

function printfl() {
    local value_error_type="$1"
    local value_error_message="$2"
    case "$value_error_type" in
        "A") # Action
            printf "$MAGENTA[ # ] >$NC $value_error_message$NC"
        ;;
        "W") # Warning
            printf "$YELLOW[ * ] >$NC $value_error_message$NC"
        ;;
        "I") # Information
            printf "$GREEN[ - ] >$NC $value_error_message$NC"
        ;;
        "E") # Error
            printf "$RED[ ! ] >$NC $value_error_message$NC"
        ;;
        *) # Regular
            printf "$GRAY[ + ] >$NC $value_error_message$NC"
        ;;
    esac
}

# CTRL+C
# ------------------------------
stty -echoctl # Hide ^C

cleanup() {
    if [ -d "$VAR_BUILD" ]; then rm -rf "$VAR_BUILD"; fi
}

trap_ctrlc() {
    printfl "E" "${RED}SIGINT$NC caught, exiting ...\n"
    cleanup
    exit 127
}

trap "trap_ctrlc" SIGINT

# Logo functions
# ------------------------------
function logo() {
    declare -a logo
    logo=($BLUE"@@@@@@@@@@    @@@@@@         @@@        @@@@@@   @@@@@@@ "
          "@@! @@! @@!  @@!  @@@        @@!       @@!  @@@  @@!  @@@"
          "@!! !!@ @!@  @!@!@!@!  @!@!  @!!       @!@!@!@!  @!@!@!@ "
          "!!:     !!:  !!:  !!!        !!:       !!:  !!!  !!:  !!!"
          " :      :     :   : :        : ::.: :   :   : :  :: : :: "
          "${GRAY}Virtual Machine: $VM_NAME"$NC)
    for i in "${logo[@]}"
    do
        printf "$i\n"
    done
}



# ////////////////////////////////////////////////////////////////////////// CODE ///



function check_file () {
    local value_file="$1"
    local exists=0
    if [ -f "$value_file" ]; then
        printfl "I" "File $value_file was found ... \n"
        exists=1
    else
        printfl "W" "File $value_file was not found ... \n"
    fi
    return $exists
}

function check_directory () {
    local value_directory="$1"
    local exists=0
    if [ -d "$value_directory" ]; then
        printfl "" "Directory $value_directory found\n"
        exists=1
    else
        printfl "W" "Directory $value_directory was not found\n"
    fi
    return $exists
}

function create_directory () {
    local value_directory="$1"
    check_directory "$value_directory"
    local exists="$?"
    if [ $exists -eq 0 ] ; then
        printfl "I" "Creating directory $value_directory ... \n"
        mkdir -p "$value_directory"
    fi
}

function delete_directory () {
    local value_directory="$1"
    check_directory "$value_directory"
    local exists="$?"
    if [ $exists -eq 1 ] ; then
        printfl "W" "Deleting directory $value_directory ... \n"
        rm -rf "$value_directory"
    fi
}

function download_file () {
    local value_url="$1"
    local value_path="$2"
    local value_name="$3"
    local curl_return_code=0
    create_directory "$value_path"
    printfl "I" "Downloading $value_url to $value_path ... \n"
    curl -L -S --progress-bar -C - "$value_url" -o "$value_path/$value_name" || curl_return_code=$?
    if [[ $curl_return_code -ne 0 ]]; then 
        printfl "E" "Connection to $value_url failed with return code $curl_return_code\n"
    else
        printfl "" "$(file "$value_path/$value_name")\n"
    fi
    return $curl_return_code
}

function download_virtio_drivers () {
    download_file "$VM_DRIVERS_URL" "$VAR_IMAGES" "$VM_DRIVERS_ISO_NAME"
}

function build_hd () {
    local value_action="$1"
    local value_command=0
    local value_disk_name=""
    local create_disk_command=""
    case $value_action in
        "-primary")
            value_disk_name="$VM_NAME"
            create_disk_command="qemu-img create -f "$VM_DISK_TYPE" "$VM_OUTPUT/$value_disk_name.$VM_DISK_TYPE" "$VM_DISK_SIZE""
            value_command=1
        ;;
        "-secondary")
            value_disk_name="$VM_SECONDARY_DISK_DATA_PATH"
            create_directory "$VAR_DATA/$value_disk_name"
            create_disk_command="virt-make-fs --type="$VM_SECONDARY_DISK_TYPE" --format="$VM_DISK_TYPE" --size="$VM_SECONDARY_DISK_EXTRA_SIZE" --partition=mbr --label="$value_disk_name" "$VAR_DATA/$value_disk_name" "$value_disk_name.$VM_DISK_TYPE""
            value_command=1
        ;;
        *)
            printfl "E" "Undefined build_hd action: \"$value_action\", exiting ... \n" 
        ;;
    esac
    if [[ value_command -eq 1 ]]; then
        create_directory "$VM_OUTPUT"
        local virtual_hd_disk_exists=0
        check_file "$VM_OUTPUT/$value_disk_name.$VM_DISK_TYPE" || virtual_hd_disk_exists=$?
        if [ $virtual_hd_disk_exists -eq 0 ]; then
            printfl "I" "Creating new Virtual HD $VM_SECONDARY_DISK_TYPE disk $VM_OUTPUT/$value_disk_name.$VM_DISK_TYPE ... \n"
            printfl "" "$($create_disk_command)\n"
        else
            while true
            do
                printfl "W" "Virtual HD disk $VM_OUTPUT/$value_disk_name.$VM_DISK_TYPE exists, do you want to re-create the disk? (Y|y = Yes, N|n = No)\n"
                read answer
                case $answer in
                    [yY]* )
                        printfl "" "$($create_disk_command)\n"
                        break
                    ;;
                    [nN]* )
                        break
                    ;;
                    *)
                        printfl "I" "Y|y = Yes, N|n = No\n"
                    ;;
                esac
            done
        fi
        printfl "" "$(file "$VM_OUTPUT/$value_disk_name.$VM_DISK_TYPE")\n"
    fi
}

function build_iso () {
    local value_action="$1"
    printfl "I" "Starting $value_action ISO build process ... \n"
    delete_directory "$VAR_BUILD"
    create_directory "$VAR_BUILD"
    local directory_automation="$VAR_DATA/automation"
    create_directory "$directory_automation"
    case $value_action in
        "-virtio")
            local directory_virtio="$VAR_BUILD/virtio"
            local directory_desktop="$VAR_DATA/desktop"
            local directory_copy_desktop="$VAR_BUILD/desktop"
            create_directory "$directory_virtio"
            create_directory "$directory_desktop"
            create_directory "$directory_copy_desktop"
            printfl "" "Extracting VirtIO drivers data: $(7z x "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME" -o"$directory_virtio" -y)\n"
            printfl "" "Copying automation script files:\n$(cp --verbose -r "$directory_automation/"* "$VAR_BUILD")\n"
            printfl "" "Copying desktop files:\n$(cp --verbose -r "$directory_desktop/"* "$directory_copy_desktop")\n"
            printfl "I" "Generating $VM_DATA_ISO_NAME ISO file ...\n"
            mkisofs -m '.*' -joliet-long -r "$VAR_BUILD" > "$VAR_IMAGES/$VM_DATA_ISO_NAME"
            printfl "" "$(file "$VAR_IMAGES/$VM_DATA_ISO_NAME")\n"
        ;;
        "-remix")
            # Reference: https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e
            # Password: echo ubuntu | mkpasswd -m sha512crypt --stdin
            local directory_iso_settings="$VAR_BUILD/nocloud"
            create_directory "$directory_iso_settings"
            printfl "" "Extracting ISO data: $(7z x "$VAR_IMAGES/$VM_OS_ISO" -o"$VAR_BUILD" -y)\n"
            printfl "" "Copying automation script files:\n$(cp --verbose -r "$directory_automation/"* "$directory_iso_settings")\n"
            printfl "" "Preparing ISO:\n$(rm -rfv "$VAR_BUILD/[BOOT]/")\n"
            sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' "$VAR_BUILD/boot/grub/grub.cfg"
            sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' "$VAR_BUILD/isolinux/txt.cfg"
            sed -i 's/timeout 50/timeout 10/g' "$VAR_BUILD/isolinux/isolinux.cfg"
            md5sum "$VAR_BUILD/README.diskdefines" > "$VAR_BUILD/md5sum.txt"
            sed -i 's|'"$VAR_BUILD/"'|./|g' "$VAR_BUILD/md5sum.txt"
            printfl "I" "Generating $VM_REMIX_ISO_NAME ISO file ...\n"
            mkisofs -o "$VAR_IMAGES/$VM_REMIX_ISO_NAME" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -l -V "${VM_NAME^} OS ISO" "$VAR_BUILD"
            printfl "" "$(file "$VAR_IMAGES/$VM_REMIX_ISO_NAME")\n"
        ;;
        "-regular")
            local directory_addons="$VAR_DATA/addons"
            create_directory "$directory_addons"
            printfl "" "Copying addons files:\n$(cp --verbose -r "$directory_addons/"* "$VAR_BUILD")\n"
            printfl "I" "Generating $VM_DATA_ISO_NAME ISO file ...\n"
            mkisofs -m '.*' -joliet-long -r "$VAR_BUILD" > "$VAR_IMAGES/$VM_DATA_ISO_NAME"
            printfl "" "$(file "$VAR_IMAGES/$VM_DATA_ISO_NAME")\n"
        ;;
        *)
            printfl "E" "Undefined build_iso action: \"$value_action\", exiting ... \n" 
        ;;
    esac
}

function boot_kvm () {
    local value_action="$1"
    if [ ! -f "$VAR_IMAGES/$VM_OS_ISO" ]; then
        printfl "E" "ISO file $VAR_IMAGES/$VM_OS_ISO is missing, exiting ...\n"
    else
        printfl "I" "Booting Virtual Machine $VM_NAME ... \n"
        printfl "" "OS: $OS_TYPE\n"
        printfl "" "RAM: $VM_RAM\n"
        printfl "" "CPUS: $VM_CPUS\n"
        printfl "" "HD 1: $VM_OUTPUT/$VM_NAME.$VM_DISK_TYPE\n"
        case $value_action in
            "-analysis")
                printfl "" "HD 2: $VM_OUTPUT/$VM_SECONDARY_DISK_DATA_PATH.$VM_DISK_TYPE\n"
                printfl "" "CD 1: $VAR_IMAGES/$VM_OS_ISO\n"
                printfl "" "CD 2: $VAR_IMAGES/$VM_DATA_ISO_NAME\n"
                # malnet-wan = access to internet, malnet-lan = no access to internet
                virt-install \
                    --check all=off \
                    --name="$VM_NAME" \
                    --os-type="$OS_TYPE" \
                    --os-variant="$OS_VARIANT" \
                    --arch=x86_64 \
                    --virt-type=kvm \
                    --ram="$VM_RAM" \
                    --vcpus="$VM_CPUS" \
                    --cdrom="$VAR_IMAGES/$VM_OS_ISO" \
                    --disk "$VAR_IMAGES/$VM_DATA_ISO_NAME",device=cdrom,bus=sata \
                    --disk "$VM_OUTPUT/$VM_NAME.$VM_DISK_TYPE",bus=sata,format="$VM_DISK_TYPE" \
                    --disk "$VM_OUTPUT/$VM_SECONDARY_DISK_DATA_PATH.$VM_DISK_TYPE",bus=sata,format="$VM_DISK_TYPE" \
                    --graphics spice \
                    --network network=malnet-wan,model="e1000e" \
                    --network network=malnet-lan,model="e1000e"
            ;;
            "-gateway")
                printfl "" "HD 2: $VM_OUTPUT/$VM_SECONDARY_DISK_DATA_PATH.$VM_DISK_TYPE\n"
                printfl "" "CD 1: $VAR_IMAGES/$VM_REMIX_ISO_NAME\n"
                # malnet-wan = access to internet, malnet-lan = no access to internet
                virt-install \
                    --check all=off \
                    --name="$VM_NAME" \
                    --os-type="$OS_TYPE" \
                    --arch=x86_64 \
                    --virt-type=kvm \
                    --ram="$VM_RAM" \
                    --vcpus="$VM_CPUS" \
                    --cdrom="$VAR_IMAGES/$VM_REMIX_ISO_NAME" \
                    --disk "$VM_OUTPUT/$VM_NAME.$VM_DISK_TYPE",bus=sata,format="$VM_DISK_TYPE" \
                    --disk "$VM_OUTPUT/$VM_SECONDARY_DISK_DATA_PATH.$VM_DISK_TYPE",bus=sata,format="$VM_DISK_TYPE" \
                    --graphics spice \
                    --network network=malnet-wan,model="e1000e" \
                    --network network=malnet-lan,model="e1000e"
            ;;
            *)
                printfl "E" "Undefined boot_kvm action: \"$value_action\", exiting ... \n" 
            ;;
        esac
    fi
}



# ////////////////////////////////////////////////////////////////////////// MAIN ///



# Main
# ------------------------------
function main () {
    local value_action="$action"
    if [[ "$DISPLAY_LOGO" -eq 1 ]]; then logo; fi
    printfl "A" "Action: $value_action\n"
    case "$value_action" in
        "--build-hd-primary")
            build_hd -primary
        ;;
        "--build-hd-secondary")
            build_hd -secondary
        ;;
        "--download-virtio-drivers")
            download_virtio_drivers
        ;;
        "--build-iso-virtio")
            build_iso -virtio
        ;;
        "--build-iso-remix")
            build_iso -remix
        ;;
        "--build-iso-regular")
            build_iso -regular
        ;;
        "--boot-gateway")
            boot_kvm -gateway
        ;;
        "--boot-analysis")
            boot_kvm -analysis
        ;;
        *)
            printfl "E" "$0 - Option \"$value_action\" was not recognized ...\n"
            printfl "" "$MAGENTA--download-virtio-drivers:$NC Downloads VirtIO Windows drivers\n"
            printfl "" "$MAGENTA--build-hd-primary:$NC Creates a OS Virtual HD disk\n"
            printfl "" "$MAGENTA--build-hd-secondary:$NC Creates a secondary Virtual HD disk\n"
            printfl "" "$MAGENTA--build-iso-virtio:$NC Rebuilds VirtIO drivers ISO $VAR_BUILD > $VAR_IMAGES/$VM_DATA_ISO_NAME CD-ROM disc\n"
            printfl "" "$MAGENTA--build-iso-remix:$NC Rebuilds OS Remix ISO $VAR_BUILD > $VAR_IMAGES/$VM_REMIX_ISO_NAME CD-ROM disc\n"
            printfl "" "$MAGENTA--build-iso-regular:$NC Rebuilds regular ISO $VAR_BUILD > $VAR_IMAGES/$VM_DATA_ISO_NAME CD-ROM disc\n"
            printfl "" "$MAGENTA--boot-gateway:$NC Boots Gateway VM using KVM\n"
            printfl "" "$MAGENTA--boot-analysis:$NC Boots Analysis VM using KVM\n"
        ;;
    esac
    cleanup
}

action="$1"

main "$action"