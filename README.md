![](./screenshots/ma-lab.png)

Collection of bash scripts to automate the installation of an Operating System on a virtual hard disk using KVM. The objective is to reduce the time necessary to setup a base lab.

**VMs**
- Analysis machine: Windows 7 64 Bit (tested with GSP1RMCPRXFRER_EN_DVD iso)
- Gateway machine: Ubuntu 20.04.01 Server 64 Bit

**Dependencies**
- KVM (Ubuntu `sudo apt install -y qemu qemu-kvm libvirt-daemon libvirt-clients bridge-utils virt-manager`)
- p7zip (Ubuntu `sudo apt install -y p7zip`) 
- mkisofs
- curl
- bash
