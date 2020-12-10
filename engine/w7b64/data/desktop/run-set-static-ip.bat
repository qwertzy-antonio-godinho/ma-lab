@echo off
@echo ******************************************************************
@echo *                                                                *
@echo *   Don't forget to first remove the Virtual Network Interface   *
@echo *   'malnet-wan' NIC adapter using virt-viewer manager           *
@echo *                                                                *
@echo *   VM SETTINGS:                                                 *
@echo *   ------------                                                 *
@echo *    - Static IP : 192.168.200.20 (Analysis VM IP Address)       *
@echo *    - Subnet    : 255.255.255.0                                 *
@echo *    - Gateway   : 192.168.200.10 (Gateway VM IP Address)        *
@echo *    - DNS Server: 192.168.200.10 (Gateway VM IP Address)        *
@echo *                                                                *
@echo ******************************************************************
:ask
@echo Do you want change Local Area Connection 2 and run services-off.ps1 script?
@echo (Y/N)
set INPUT=
set /P INPUT=Answer: %=%
If /I "%INPUT%"=="y" goto yes 
If /I "%INPUT%"=="n" goto no
goto ask
:yes
netsh interface ipv4 set address "Local Area Connection 2" static 192.168.200.20 255.255.255.0 192.168.200.10 1
netsh interface ipv4 set dns "Local Area Connection 2" static 192.168.200.10
powershell.exe set-executionpolicy remotesigned -force
powershell.exe -executionpolicy bypass ./services-off.ps1
goto exit
:no
goto exit
:exit
@echo on
