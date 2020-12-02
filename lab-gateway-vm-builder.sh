#! /bin/bash

# Start
# ------------------------------

SBD=$(dirname "$0")
DISPLAY_LOGO=1

# VM Settings
# ------------------------------

VM_NAME="gateway"
VM_DISK_SIZE="80G"
VM_DISK_TYPE="qcow2"

# VM ISOs
# ------------------------------

VM_OS_ISO="ubuntu-20.04-live-server-amd64.iso"
#VM_DRIVERS_URL="https://fedorapeople.org/groups/virt/virtio-win/deprecated-isos/latest/virtio-win-0.1-100.iso"
#VM_DRIVERS_ISO_NAME="virtio-windows-drivers.iso"
VM_REMIX_ISO_NAME="ubuntu-20.04-live-server-remixed-amd64.iso"
VM_DATA_ISO_NAME="gateway-data.iso"

# Paths
# ------------------------------

VAR_IMAGES="$SBD/images"
VAR_BUILD="$SBD/build/$VM_NAME"
VAR_DATA="$SBD/data/$VM_NAME"
VAR_OUTPUT="$SBD/disks"

# ////////////////////////////////////////////////////////////////////////// CODE ///



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
        "W") # Warning
            printf "$YELLOW[ * ] >$NC $value_error_message$NC"
        ;;
        "I") # Information
            printf "$GREEN[ # ] >$NC $value_error_message$NC"
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
    printfl "E" "${RED}SIGINT$NC caught, exiting ...\n\n"
    cleanup
    exit 127
}

trap "trap_ctrlc" SIGINT

# Hypervisor architecture detection
# ------------------------------

if [ $(arch) = "x86_64" ]; then QEMU_EXECUTABLE="qemu-system-x86_64"; else QEMU_EXECUTABLE="qemu-system-i386"; fi

# Logo functions
# ------------------------------

function logo() {
    declare -a logo
    logo=($BLUE"@@@@@@@@@@    @@@@@@         @@@        @@@@@@   @@@@@@@ "
          "@@! @@! @@!  @@!  @@@        @@!       @@!  @@@  @@!  @@@"
          "@!! !!@ @!@  @!@!@!@!  @!@!  @!!       @!@!@!@!  @!@!@!@ "
          "!!:     !!:  !!:  !!!        !!:       !!:  !!!  !!:  !!!"
          " :      :     :   : :        : ::.: :   :   : :  :: : :: "
          ""
          "${GRAY}Virtual Machine: $VM_NAME"
          $NC)
    for i in "${logo[@]}"
    do
        printf "$i\n"
    done
}

# VM functions
# ------------------------------

function download_virtio_drivers () {
    if [ ! -d "$VAR_IMAGES" ]; then mkdir -p "$VAR_IMAGES"; fi
    local curl_virtio_return_code=0
    printfl "I" "Downloading Virtio drivers ISO file ... \n"
    curl -L -S --progress-bar -C - "$VM_DRIVERS_URL" -o "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME" || curl_virtio_return_code=$?
    if [ $curl_virtio_return_code -ne 0 ]; then 
        printfl "E" "Connection to $VM_DRIVERS_URL failed with return code $RED$curl_virtio_return_code$NC\n\n"
        exit "$curl_virtio_return_code"
    fi
    printfl "" "$(file "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME")\n"
}

function create_virtual_hdd_disk () {
    if [ ! -d "$VAR_OUTPUT" ]; then mkdir -p "$VAR_OUTPUT"; fi
    local create_disk_command="qemu-img create -f "$VM_DISK_TYPE" "$VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE" "$VM_DISK_SIZE""
    if [ ! -f "$VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE" ]; then
        printfl "I" "Creating new virtual disk $VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE ... \n"
        printfl "" "$($create_disk_command)\n"
    else
        while true
        do
            printfl "W" "Virtual disk $VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE exists, do you want to format the disk? (Y|y = format, N|n = boot disk)\n"
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
                    printfl "I" "Y|y = yes, N|n = no.\n"
                ;;
            esac
        done
    fi
    printfl "" "$(file "$VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE")\n"
}

function build_cdrom_disc () {
    if [ ! -d "$VAR_BUILD" ]; then mkdir -p "$VAR_BUILD"; else rm -rf "$VAR_BUILD"; fi
    printfl "I" "Starting $VM_DATA_ISO_NAME build process ... \n"
    if [ ! -d "$VAR_DATA" ]; then mkdir -p "$VAR_DATA/$VM_NAME"; fi
    # printfl "" "Extracting Virtio drivers data: $(7z x "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME" -o"$VAR_BUILD/drivers" -y)\n"
    if [ -d "$VAR_DATA/$tools" ]; then printfl "" "Copying tools files:\n$(cp --verbose -r "$VAR_DATA/tools/"* "$VAR_BUILD")\n"; fi
    #printfl "" "Copying automation script files:\n$(cp --verbose -r "$VAR_DATA/automation/"* "$VAR_BUILD")\n"
    printfl "I" "Generating $VM_DATA_ISO_NAME ISO file ...\n"
    mkisofs -m '.*' -J -r "$VAR_BUILD" > "$VAR_IMAGES/$VM_DATA_ISO_NAME"
    printfl "" "$(file "$VAR_IMAGES/$VM_DATA_ISO_NAME")\n"
}

# Reference: https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e
# Password: echo ubuntu | mkpasswd -m sha512crypt --stdin

function build_remix_disc () {
    if [ ! -d "$VAR_BUILD" ]; then mkdir -p "$VAR_BUILD"; else rm -rf "$VAR_BUILD"; fi
    printfl "I" "Starting $VM_REMIX_ISO_NAME remix build process ... \n"
    if [ ! -d "$VAR_DATA" ]; then mkdir -p "$VAR_DATA"; fi
    printfl "" "Extracting OS data: $(7z x "$VAR_IMAGES/$VM_OS_ISO" -o"$VAR_BUILD/$VM_NAME" -y)\n"
    if [ ! -d "$VAR_BUILD/$VM_NAME/nocloud" ]; then mkdir -p "$VAR_BUILD/$VM_NAME/nocloud"; fi
    printfl "" "Copying automation script files:\n$(cp --verbose -r "$VAR_DATA/automation/"* "$VAR_BUILD/$VM_NAME/nocloud")\n"
    printfl "" "Preparing ISO:\n$(rm -rf "$VAR_BUILD/$VM_NAME/[BOOT]/")\n"
    sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' "$VAR_BUILD/$VM_NAME/boot/grub/grub.cfg"
    sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' "$VAR_BUILD/$VM_NAME/isolinux/txt.cfg"
    sed -i 's/timeout 50/timeout 10/g' "$VAR_BUILD/$VM_NAME/isolinux/isolinux.cfg"
    md5sum "$VAR_BUILD/$VM_NAME/README.diskdefines" > "$VAR_BUILD/$VM_NAME/md5sum.txt"
    sed -i 's|'"$VAR_BUILD/$VM_NAME/"'|./|g' "$VAR_BUILD/$VM_NAME/md5sum.txt"
    mkisofs -o "$VAR_IMAGES/$VM_REMIX_ISO_NAME" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -l -V "${VM_NAME^} OS ISO" "$VAR_BUILD/$VM_NAME"
    printfl "" "$(file "$VAR_IMAGES/$VM_REMIX_ISO_NAME")\n"
}

function boot_qemu () {
    printfl "W" "QEMU binary: $QEMU_EXECUTABLE\n"
    if [ ! -f "$VAR_IMAGES/$VM_REMIX_ISO_NAME" ]; then
        printfl "E" "ISO ${RED}file $VAR_IMAGES/$VM_REMIX_ISO_NAME missing$NC, exiting ...\n"
    else
        printfl "I" "Booting virtual disk $VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE [CD1: $VAR_IMAGES/$VM_REMIX_ISO_NAME, CD2: $VAR_IMAGES/$VM_DATA_ISO_NAME] ...\n"
        # malnet-wan = access to internet, malnet-lan = no access to internet
        $QEMU_EXECUTABLE \
            -machine pc,accel=kvm -m 4G -vga std \
            -net user -net nic,model=rtl8139,id=malnet-wan \
            -device virtio-scsi-pci -device scsi-hd,drive=vd0 \
            -drive if=none,aio=native,cache=none,discard=unmap,file="$VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE",id=vd0 \
            -drive media=cdrom,file="$VAR_IMAGES/$VM_REMIX_ISO_NAME" \
            -drive media=cdrom,file="$VAR_IMAGES/$VM_DATA_ISO_NAME"
    fi
}

function boot_kvm () {
    if [ ! -f "$VAR_IMAGES/$VM_REMIX_ISO_NAME" ]; then
        printfl "E" "ISO ${RED}file $VAR_IMAGES/$VM_REMIX_ISO_NAME missing$NC, exiting ...\n"
    else
        printfl "I" "Booting virtual disk $VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE [CD1: $VAR_IMAGES/$VM_REMIX_ISO_NAME, CD2: $VAR_IMAGES/$VM_DATA_ISO_NAME] ...\n"
        # malnet-wan = access to internet, malnet-lan = no access to internet
        virt-install \
            --check all=off \
            --name="$VM_NAME" \
            --os-type=Windows \
            --os-variant=win7 \
            --arch=x86_64 \
            --virt-type=kvm \
            --ram=4096 \
            --vcpus=2 \
            --cdrom="$VAR_IMAGES/$VM_REMIX_ISO_NAME" \
            --disk "$VAR_IMAGES/$VM_DATA_ISO_NAME",device=cdrom,bus=sata \
            --disk "$VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE",bus=sata,format="$VM_DISK_TYPE" \
            --graphics spice \
            --network network=malnet-wan \
            --network network=malnet-lan
    fi
}

function build () {
    #download_virtio_drivers
    create_virtual_hdd_disk
    build_cdrom_disc
    build_remix_disc
    cleanup
    printfl "I" "Build process complete, exiting ...\n"
    printfl "W" "Use $0 --boot-qemu or $0 --boot-kvm to install the OS on the virtual disk image\n"
}

# ////////////////////////////////////////////////////////////////////////// MAIN ///



# Main
# ------------------------------

function main () {
    local value_action="$action"
    local value_parameters="$parameters"
    printf "\n"
    if [ "$DISPLAY_LOGO" -eq 1 ]; then logo; fi
    printfl "I" "Action: $value_action\n"
    printfl "I" "Parameters: $value_parameters\n"
    local missing_variables=()
    if [ ! -n "$VM_OS_ISO" ]; then missing_variables+=("VM_OS_ISO"); fi
    # if [ ! -n "$VM_DRIVERS_URL" ]; then missing_variables+=("VM_DRIVERS_URL"); fi
    # if [ ! -n "$VM_DRIVERS_ISO_NAME" ]; then missing_variables+=("VM_DRIVERS_ISO_NAME"); fi
    if [ ! -n "$VM_REMIX_ISO_NAME" ]; then missing_variables+=("VM_REMIX_ISO_NAME"); fi
    if [ ! -n "$VM_DATA_ISO_NAME" ]; then missing_variables+=("VM_DATA_ISO_NAME"); fi
    if [ ! -n "$VM_NAME" ]; then missing_variables+=("VM_NAME"); fi
    if [ ! -n "$VM_DISK_SIZE" ]; then missing_variables+=("VM_DISK_SIZE"); fi
    if [ ! -n "$VM_DISK_TYPE" ]; then missing_variables+=("VM_DISK_TYPE"); fi
    if [ ! -n "$VAR_IMAGES" ]; then missing_variables+=("VAR_IMAGES"); fi
    if [ ! -n "$VAR_BUILD" ]; then missing_variables+=("VAR_BUILD"); fi
    if [ ! -n "$VAR_DATA" ]; then missing_variables+=("VAR_DATA"); fi
    if [ ! -n "$VAR_OUTPUT" ]; then missing_variables+=("VAR_OUTPUT"); fi
    if [ ${#missing_variables[@]} -ne 0 ]; then
        printfl "E" "Missing variable(s): ${missing_variables[*]}\n"
    else
        case "$value_action" in
            "--build")
                build
            ;;
            "--build-cdrom-disc")
                build_cdrom_disc
            ;;
            "--build-remix-disc")
                build_remix_disc
            ;;
            "--boot-qemu")
                boot_qemu
            ;;
            "--boot-kvm")
                boot_kvm
            ;;
            *)
                printfl "E" "$0 - Option \"$RED$value_action$NC\" was not recognized ...\n"
                printfl "" "$MAGENTA--build:$NC Bootstraps build process\n"
                printfl "" "$MAGENTA--build-cdrom-disc:$NC Rebuilds $VAR_BUILD > $VAR_IMAGES/$VM_DATA_ISO_NAME CD-ROM disc\n"
                printfl "" "$MAGENTA--build-remix-disc:$NC Remixes $VM_OS_ISO > $VAR_IMAGES/$VM_REMIX_ISO_NAME CD-ROM disc\n"
                printfl "" "$MAGENTA--boot-qemu:$NC Boots $VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE using QEMU\n"
                printfl "" "$MAGENTA--boot-kvm:$NC Boots $VAR_OUTPUT/$VM_NAME.$VM_DISK_TYPE using KVM\n"
            ;;
        esac
    fi
    printf "\n"
}

action="$1"
parameters="${*: 2}"

main "$action" "$parameters"
