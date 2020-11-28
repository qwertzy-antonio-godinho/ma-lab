#! /bin/bash

# Start
# ------------------------------

SBD=$(dirname "$0")
DISPLAY_LOGO=1

# VM Settings
# ------------------------------

VM_NAME="w7b64"
VM_DISK_SIZE=80G
VM_DISK_TYPE=qcow2

# VM ISOs
# ------------------------------

VM_WINDOWS_ISO="en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso"
VM_DRIVERS_URL="https://fedorapeople.org/groups/virt/virtio-win/deprecated-isos/latest/virtio-win-0.1-100.iso"
VM_DRIVERS_ISO_NAME="virtio-windows-drivers.iso"
VM_DATA_ISO_NAME="windows-data.iso"
VM_DATA_TOOLS_ARCHIVE="tools.7z"

# Paths
# ------------------------------

VAR_IMAGES="$SBD/images"
VAR_BUILD="$SBD/build/$VM_NAME"
VAR_DATA="$SBD/data/$VM_NAME"

# ////////////////////////////////////////////////////////////////////////// CODE ///



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
    printfl "E" "${RED}SIGINT$NC caught, exiting ...\n\n"
    if [ -d "$VAR_BUILD" ]; then rm -rf "$VAR_BUILD"; fi
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
          ""
          "${GRAY}Virtual Machine: $VM_NAME"
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

function build () {
    if [ ! -d "$VAR_IMAGES" ]; then mkdir -p "$VAR_IMAGES"; fi
    local curl_virtio_return_code=0
    if [ ! -e "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME" ]; then
        printfl "I" "Downloading Virtio drivers ISO file ... \n"
        curl -L -S --progress-bar -C - "$VM_DRIVERS_URL" -o "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME" || curl_virtio_return_code=$?
        if [ $curl_virtio_return_code -ne 0 ]; then printfl "E" "Connection to $VM_DRIVERS_URL failed with return code $RED$curl_virtio_return_code$NC\n\n"; exit "$curl_virtio_return_code"; fi
    else
        printfl "" "$(file "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME")\n"
    fi
    if [ ! -f "$SBD/$VM_NAME.$VM_DISK_TYPE" ]; then
        printfl "I" "Creating new virtual disk $SBD/$VM_NAME.$VM_DISK_TYPE ... \n"
        printfl "" "$(qemu-img create -f "$VM_DISK_TYPE" "$SBD/$VM_NAME.$VM_DISK_TYPE" "$VM_DISK_SIZE")\n"
    else
        while true
        do
            printfl "W" "Virtual disk $SBD/$VM_NAME.$VM_DISK_TYPE exists, do you want to format the disk? (Y|y = format, N|n = boot disk)\n"
            read answer
            case $answer in
                [yY]* )
                    printfl "" "$(qemu-img create -f "$VM_DISK_TYPE" "$SBD/$VM_NAME.$VM_DISK_TYPE" "$VM_DISK_SIZE")\n"
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
    printfl "" "$(file "$SBD/$VM_NAME.$VM_DISK_TYPE")\n"
    if [ ! -d "$VAR_BUILD" ]; then mkdir -p "$VAR_BUILD"; else rm -rf "$VAR_BUILD"; fi
    printfl "I" "Starting $VM_DATA_ISO_NAME build process ... \n"
    if [ ! -d "$VAR_DATA" ]; then mkdir -p "$VAR_DATA"; fi
    printfl "" "Extracting Virtio drivers data: $(7z x "$VAR_IMAGES/$VM_DRIVERS_ISO_NAME" -o"$VAR_BUILD/drivers" -y)\n"
    if [ -f "$VAR_DATA/$VM_DATA_TOOLS_ARCHIVE" ]; then printfl "" "Extracting $VM_DATA_TOOLS_ARCHIVE data: $(7z x "$VAR_DATA/$VM_DATA_TOOLS_ARCHIVE" -o"$VAR_BUILD/" -y)\n"; fi
    printfl "" "Copying automation script files:\n$(cp --verbose -r "$VAR_DATA/automation/"* "$VAR_BUILD")\n"
    printfl "I" "Generating $VM_DATA_ISO_NAME ISO file ...\n"
    mkisofs -quiet -m '.*' -J -r "$VAR_BUILD" > "$VAR_IMAGES/$VM_DATA_ISO_NAME"
    printfl "" "$(file "$VAR_IMAGES/$VM_DATA_ISO_NAME")\n"
    if [ ! -f "$VAR_IMAGES/$VM_WINDOWS_ISO" ]; then
        printfl "E" "Windows ISO ${RED}file $VAR_IMAGES/$VM_WINDOWS_ISO missing$NC, exiting ...\n"
    else
        printfl "I" "Booting virtual disk $SBD/$VM_NAME.$VM_DISK_TYPE [CD1: $VAR_IMAGES/$VM_WINDOWS_ISO, CD2: $VAR_IMAGES/$VM_DATA_ISO_NAME] ...\n"
        # malnet-wan = access to internet, malnet-lan = no access to internet
        $QEMU_EXECUTABLE \
            -machine pc,accel=kvm -m 2G -vga std \
            -net user -net nic,model=rtl8139,id=malnet-wan \
            -device virtio-scsi-pci -device scsi-hd,drive=vd0 \
            -drive if=none,aio=native,cache=none,discard=unmap,file="$SBD/$VM_NAME.$VM_DISK_TYPE",id=vd0 \
            -drive media=cdrom,file="$VAR_IMAGES/$VM_WINDOWS_ISO" \
            -drive media=cdrom,file="$VAR_IMAGES/$VM_DATA_ISO_NAME"
    fi
    if [ -d "$VAR_BUILD" ]; then rm -rf "$VAR_BUILD"; fi
    printfl "I" "Process complete, exiting ...\n"
}



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
    if [ ! -n "$VM_WINDOWS_ISO" ]; then missing_variables+=("VM_WINDOWS_ISO"); fi
    if [ ! -n "$VM_DRIVERS_URL" ]; then missing_variables+=("VM_DRIVERS_URL"); fi
    if [ ! -n "$VM_DRIVERS_ISO_NAME" ]; then missing_variables+=("VM_DRIVERS_ISO_NAME"); fi
    if [ ! -n "$VM_DATA_ISO_NAME" ]; then missing_variables+=("VM_DATA_ISO_NAME"); fi
    if [ ! -n "$VM_DATA_TOOLS_ARCHIVE" ]; then missing_variables+=("VM_DATA_TOOLS_ARCHIVE"); fi
    if [ ! -n "$VM_NAME" ]; then missing_variables+=("VM_NAME"); fi
    if [ ! -n "$VM_DISK_SIZE" ]; then missing_variables+=("VM_DISK_SIZE"); fi
    if [ ! -n "$VM_DISK_TYPE" ]; then missing_variables+=("VM_DISK_TYPE"); fi
    if [ ! -n "$VAR_IMAGES" ]; then missing_variables+=("VAR_IMAGES"); fi
    if [ ! -n "$VAR_BUILD" ]; then missing_variables+=("VAR_BUILD"); fi
    if [ ! -n "$VAR_DATA" ]; then missing_variables+=("VAR_DATA"); fi
    if [ ${#missing_variables[@]} -ne 0 ]; then
        printfl "E" "Missing variable(s): ${missing_variables[*]}\n"
    else
        case "$value_action" in
            "--build")
                build
            ;;
            *)
                printfl "E" "$0 - Option \"$RED$value_action$NC\" was not recognized ...\n"
                printfl "" "$MAGENTA--build:$NC Starts installation of the OS on a virtual disk file\n"
            ;;
        esac
    fi
    printf "\n"
}

action="$1"
parameters="${*: 2}"

main "$action" "$parameters"
