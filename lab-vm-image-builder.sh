#! /bin/bash

## Ubuntu ISO
VM_ISO_GATEWAY="./media/ubuntu-20.04-live-server-amd64.iso"
## Windows ISO
VM_ISO_ANALYSIS="./media/en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso"

## -------------------------------------------------

VM_HDD_GATEWAY="./vm/vm-w7-64/images/vm-w7-64.qcow2"
VM_HDD_ANALYSIS="./vm/vm-gateway/images/vm-gateway.qcow2"
VM_BOOTSTRAP_ANALYSIS="./media/virtio-windows-bootstrap.iso"

if [ $(arch) = "x86_64" ]; then QEMU_EXECUTABLE="qemu-system-x86_64"; else QEMU_EXECUTABLE="qemu-system-i386"; fi

## QEMU emulation settings for installation

$QEMU_EXECUTABLE \
    -machine pc,accel=kvm -m 2G -vga std \
    -net user -net nic,model=rtl8139,id=malnet-wan \
    -device virtio-scsi-pci -device scsi-hd,drive=vd0 \
    -drive if=none,aio=native,cache=none,discard=unmap,file="$VM_HDD_ANALYSIS",id=vd0 \
    -drive media=cdrom,file="$VM_ISO_ANALYSIS" \
    -drive media=cdrom,file="$VM_BOOTSTRAP_ANALYSIS"