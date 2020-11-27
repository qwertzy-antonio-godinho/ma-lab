#! /bin/bash

# VM ISOs
# ------------------------------

VM_WINDOWS_ISO="en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso"
VM_DRIVERS_URL="https://fedorapeople.org/groups/virt/virtio-win/deprecated-isos/latest/virtio-win-0.1-100.iso"
VM_DRIVERS_ISO_NAME="virtio-windows-drivers.iso"
VM_DATA_ISO_NAME="windows-data.iso"

# VM Settings
# ------------------------------

VM_NAME="WIN7-64"
VM_DISK_SIZE=80G
VM_DISK_TYPE=qcow2

# //////////////////////////////////////////////////////////////////////////

# Start
# ------------------------------

SBD=$(dirname "$0")
NOW=$(date +"%Y%m%d%H%M%S")
LOG="$SBD/logs/$NOW-$(basename $0).log"
DISPLAY_LOGO=1

# Colour palette
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

# CTRL+C
# ------------------------------

stty -echoctl # Hide ^C

trap_ctrlc() {
    printfl "E" "SIGINT caught, exiting ...\n\n"
    if [ -d "$SBD/build" ]; then rm -rf "$SBD/build"; fi
    exit 127
}

trap "trap_ctrlc" SIGINT

# QEMU
# ------------------------------

if [ $(arch) = "x86_64" ]; then QEMU_EXECUTABLE="qemu-system-x86_64"; else QEMU_EXECUTABLE="qemu-system-i386"; fi

# Screen helpers
# ------------------------------

function logo() {
    declare -a logo
    logo=($BLUE"@@@@@@@@@@    @@@@@@         @@@        @@@@@@   @@@@@@@ "
          "@@! @@! @@!  @@!  @@@        @@!       @@!  @@@  @@!  @@@"
          "@!! !!@ @!@  @!@!@!@!  @!@!  @!!       @!@!@!@!  @!@!@!@ "
          "!!:     !!:  !!:  !!!        !!:       !!:  !!!  !!:  !!!"
          " :      :     :   : :        : ::.: :   :   : :  :: : :: "
          $NC)
    for i in "${logo[@]}"
    do
        printf "$i\n"
    done
}

# VM helpers
# ------------------------------

function printfl() {
    local value_error_type="$1"
    local value_error_message="$2"
    local value_message_id=""
    case "$value_error_type" in
        "W") # Warning
            value_message_id="[ # ] > "
            printf "$YELLOW$value_message_id$NC$value_error_message$NC"
        ;;
        "L") # Log
            value_message_id="[ + ] > "
        ;;
        "I") # Information
            value_message_id="[ * ] > "
            printf "$GREEN$value_message_id$NC$value_error_message$NC"
        ;;
        "E") # Error
            value_message_id="[ ! ] > "
            printf "$RED$value_message_id$NC$value_error_message$NC"
        ;;
        *) # Regular
            value_message_id="[ - ] > "
            printf "$GRAY$value_message_id$NC$value_error_message$NC"
        ;;
    esac
    printf "$value_message_id $value_error_message" >> "$LOG"
}

function build () {
    if [ ! -d "$SBD/images" ]; then mkdir "$SBD/images"; fi
    local curl_return_code=0
    if [ ! -e "$SBD/images/$VM_DRIVERS_ISO_NAME" ]; then
        printfl "I" "Downloading Virtio drivers ISO file ... \n"
        curl -L -S --progress-bar -C - "$VM_DRIVERS_URL" -o "$SBD/images/$VM_DRIVERS_ISO_NAME" || curl_return_code=$?
        if [ $curl_return_code -ne 0 ]; then printfl "E" "Connection to $VM_DRIVERS_URL failed with return code $curl_return_code\n\n"; exit "$curl_return_code"; fi
    else
        printfl "" "$(file "$SBD/images/$VM_DRIVERS_ISO_NAME")\n"
    fi
    if [ ! -f "$SBD/$VM_NAME.$VM_DISK_TYPE" ]; then
        printfl "I" "Creating new virtual disk $SBD/$VM_NAME.$VM_DISK_TYPE ... \n"
        printfl "" "$(qemu-img create -f "$VM_DISK_TYPE" "$SBD/$VM_NAME.$VM_DISK_TYPE" "$VM_DISK_SIZE")\n"
    else
        while true
        do
            printfl "W" "Virtual disk $SBD/$VM_NAME.$VM_DISK_TYPE exists, do you want to format the disk? (Y|y = format, N|n = boot disk)\n"
            read answer
            printfl "L" "$answer\n"
            case $answer in
                [yY]* )
                    printfl "" "$(qemu-img create -f "$VM_DISK_TYPE" "$SBD/$VM_NAME.$VM_DISK_TYPE" "$VM_DISK_SIZE")\n"
                    break
                ;;
                [nN]* )
                    printfl "I" "Booting virtual disk $SBD/$VM_NAME.$VM_DISK_TYPE ... \n"
                    break
                ;;
                *)
                    printfl "I" "Y|y = yes, N|n = no.\n"
                ;;
            esac
        done
    fi
    printfl "" "$(file "$SBD/$VM_NAME.$VM_DISK_TYPE")\n"
    if [ ! -d "$SBD/build" ]; then mkdir "$SBD/build"; else rm -rf "$SBD/build"; fi
    printfl "I" "Building $VM_DATA_ISO_NAME ISO file ... \n"
    if [ ! -d "$SBD/data" ]; then mkdir "$SBD/data"; fi
    printfl "I" "Extracting data: $(7z x "$SBD/images/$VM_DRIVERS_ISO_NAME" -o"$SBD/build" -y)\n"
    printfl "I" "Copying data files:\n$(cp --verbose -r "$SBD/data/autounattend.xml" "$SBD/data/vm-setup.ps1" "$SBD/build")\n"
    printfl "I" "Building data ISO file ...\n"
    mkisofs -m '.*' -J -r "$SBD/build" > "$SBD/images/$VM_DATA_ISO_NAME"
    printfl "" "$(file "$SBD/images/$VM_DATA_ISO_NAME")\n"
    if [ ! -f "$SBD/images/$VM_WINDOWS_ISO" ]; then
        printfl "E" "Windows ISO file not found ...\n"
    else
        printfl "I" "Booting $SBD/$VM_NAME.$VM_DISK_TYPE file [CD1: $SBD/images/$VM_WINDOWS_ISO, CD2: $SBD/images/$VM_DATA_ISO_NAME] ...\n"
        $QEMU_EXECUTABLE \
            -machine pc,accel=kvm -m 2G -vga std \
            -net user -net nic,model=rtl8139,id=malnet-wan \
            -device virtio-scsi-pci -device scsi-hd,drive=vd0 \
            -drive if=none,aio=native,cache=none,discard=unmap,file="$SBD/$VM_NAME.$VM_DISK_TYPE",id=vd0 \
            -drive media=cdrom,file="$SBD/images/$VM_WINDOWS_ISO" \
            -drive media=cdrom,file="$SBD/images/$VM_DATA_ISO_NAME"
    fi
    if [ -d "$SBD/build" ]; then rm -rf "$SBD/build"; fi
    printfl "I" "Process complete, exiting ...\n"
}



# Main
# ------------------------------

function main () {
    local value_action="$action"
    local value_parameters="$parameters"
    printf "\n"
    if [ "$DISPLAY_LOGO" -eq 1 ]; then logo; fi
    if [ ! -d "$SBD/logs" ]; then mkdir "$SBD/logs"; fi
    printfl "I" "Logging to file $LOG ...\n"
    printfl "L" "Action: $value_action\n"
    printfl "L" "Parameters: $value_parameters\n"
    local missing_variables=()
    if [ ! -n "$VM_WINDOWS_ISO" ]; then missing_variables+=("VM_WINDOWS_ISO"); fi
    if [ ! -n "$VM_DRIVERS_URL" ]; then missing_variables+=("VM_DRIVERS_URL"); fi
    if [ ! -n "$VM_DRIVERS_ISO_NAME" ]; then missing_variables+=("VM_DRIVERS_ISO_NAME"); fi
    if [ ! -n "$VM_DATA_ISO_NAME" ]; then missing_variables+=("VM_DATA_ISO_NAME"); fi
    if [ ! -n "$VM_NAME" ]; then missing_variables+=("VM_NAME"); fi
    if [ ! -n "$VM_DISK_SIZE" ]; then missing_variables+=("VM_DISK_SIZE"); fi
    if [ ! -n "$VM_DISK_TYPE" ]; then missing_variables+=("VM_DISK_TYPE"); fi
    if [ ${#missing_variables[@]} -ne 0 ]; then
        printfl "E" "Missing variable(s): ${missing_variables[*]}\n"
    else
        case "$value_action" in
            "--build")
                build
            ;;
            *)
                printfl "E" "$0 - Option \"$value_action\" was not recognized ...\n"
                printfl "" "--build       : Starts installation process on a virtual disk, if the virtual disk exists boots OS virtual disk, else willfor installation\n"
            ;;
        esac
    fi
    printf "\n"
}

action="$1"
parameters="${*: 2}"

main "$action" "$parameters"
