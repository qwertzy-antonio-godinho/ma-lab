# ma-lab
Lab using KVM and QEMU

**VMs**
- Analysis: Windows 7 64 (GSP1RMCPRXFRER_EN_DVD)
- TODO: Gateway VM: Ubuntu 20.04 Server

**Supported**
- Windows 7 64 Bits (Analysis VM)

**Usage**
1. Network NAT interface
- `lab-network.sh --define network-malnet-nat.xml` (only needed once)
- `lab-network.sh --autostart network-malnet-nat.xml` (only needed once, if required)
- `lab-network.sh --up network-malnet-nat.xml` (only needed after rebooting if no autostart is set)

2. Copy a Windows 7 64 Bit ISO file into `images` directory

3. In `lab-win7-64-vm-builder.sh` file change variable VM_WINDOWS_ISO to match the Windows ISO file amd customize VM_NAME, VM_DISK_SIZE and VM_DISK_TYPE variables. Optionaly configure `autounattend.xml` and `vm-setup.ps1` file.

4. Install OS into VM by running `lab-win7-64-vm-builder.sh --build`.

**Script description**
- `lab-win7-64-vm-builder.sh` : Runs QEMU and installs the OS. No username or password necessary to login.

![](./screenshots/lab-win7-64-vm-builder.png)

- `lab-network.sh` : Manages the lab network (bridges and states), definition XML files inside network directory. 
- *`network-malnet-nat.xml`* : NAT network (name is malnet-wan, address='192.168.200.1', netmask='255.255.255.0', dhcp range start='192.168.200.2' end='192.168.200.254')
- *`network-malnet-internal.xml`* : Private internal network (name is malnet-internal, mac address='B4:2E:99:3D:A8:43')

![](./screenshots/lab-network.png)

- `get-windows-key.sh` : Scrapes Microsoft Windows https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys page for Windows Serial Keys and displays them in the terminal. **Serials provided by Microsoft**.

![](./screenshots/get-windows-key.png)
