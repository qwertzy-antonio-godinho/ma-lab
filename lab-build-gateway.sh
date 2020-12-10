#! /bin/bash

CWD=$(dirname "$0")
ENGINE="$CWD/engine"
DISPLAY_LOGO=1

# OS Settings
# ------------------------------
OS_TYPE="linux"

# VM Settings
# ------------------------------
VM_NAME="gateway"
VM_DISK_SIZE="80G"
VM_DISK_TYPE="qcow2"
VM_RAM="4096"
VM_CPUS="2"
VM_SECONDARY_DISK_DATA_PATH="$VM_NAME-tools"
VM_SECONDARY_DISK_TYPE="ext3"
VM_SECONDARY_DISK_EXTRA_SIZE="+100M"
# VM ISOs
# ------------------------------
VM_OS_ISO="ubuntu-20.04.1-live-server-amd64.iso"
VM_REMIX_ISO_NAME="ubuntu-20.04-live-server-remixed-amd64.iso"


# Paths
# ------------------------------
VM_OUTPUT="$CWD"



# ////////////////////////////////////////////////////////////////////////// MAIN ///



# Main
# ------------------------------
function manage () {
    local missing_variables=()
    if [ ! -n "$OS_TYPE" ]; then missing_variables+=("OS_TYPE"); fi
    if [ ! -n "$VM_NAME" ]; then missing_variables+=("VM_NAME"); fi
    if [ ! -n "$VM_DISK_SIZE" ]; then missing_variables+=("VM_DISK_SIZE"); fi
    if [ ! -n "$VM_DISK_TYPE" ]; then missing_variables+=("VM_DISK_TYPE"); fi
    if [ ! -n "$VM_RAM" ]; then missing_variables+=("VM_RAM"); fi
    if [ ! -n "$VM_CPUS" ]; then missing_variables+=("VM_CPUS"); fi
    if [ ! -n "$VM_SECONDARY_DISK_DATA_PATH" ]; then missing_variables+=("VM_SECONDARY_DISK_DATA_PATH"); fi
    if [ ! -n "$VM_SECONDARY_DISK_TYPE" ]; then missing_variables+=("VM_SECONDARY_DISK_TYPE"); fi
    if [ ! -n "$VM_SECONDARY_DISK_EXTRA_SIZE" ]; then missing_variables+=("VM_SECONDARY_DISK_EXTRA_SIZE"); fi
    if [ ! -n "$VM_OS_ISO" ]; then missing_variables+=("VM_OS_ISO"); fi
    if [ ! -n "$VM_REMIX_ISO_NAME" ]; then missing_variables+=("VM_REMIX_ISO_NAME"); fi
    if [ ! -n "$VM_OUTPUT" ]; then missing_variables+=("VM_OUTPUT"); fi
    if [ ${#missing_variables[@]} -ne 0 ]; then
        printf "$0 *** ERROR: - Missing variable(s): ${missing_variables[*]}\n"
    else
        case "$1" in
            "--build")
                source "$ENGINE/lab-manager.sh" "--build-hd-primary"
                source "$ENGINE/lab-manager.sh" "--build-hd-secondary"
                source "$ENGINE/lab-manager.sh" "--build-iso-remix"
                source "$ENGINE/lab-manager.sh" "--boot-gateway"
            ;;
            "--regen-hd")
                source "$ENGINE/lab-manager.sh" "--build-hd-secondary"
            ;;
            *)
                printf "$0 - Option \"$1\" was not recognized ...\n"
                printf "   --build   : Builds and imports $VM_NAME VM using virt-install\n"
                printf "   --regen-hd: Regenerates $VM_SECONDARY_DISK_DATA_PATH HD disk\n"
            ;;
        esac
    fi
}

manage "$1"