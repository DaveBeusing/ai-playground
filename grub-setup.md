# Undo Grub installation
In case Grub ended up on the Windows SSD

> Open a Windows terminal as an administrator
```
PS C:\Users\anon> diskpart
```
Find the EFI partition
```
DISKPART> list disk
```
identify the internal Windows SSD
e.g. Disk 0
select it and look for the EFI partition usually around 100-300MB FAT32
```
DISKPART> select disk 0
DISKPART> list partition
```
or in case it's not obvious check
```
DISKPART> select disk 0
DISKPART> list volume
```
select the EFI partition and assing a drive letter 
```
DISKPART> select volume 4
DISKPART> detail volume
DISKPART> assign letter=S
exit
```
check if it is the right volume
```
PS C:\Users\anon> dir S:\EFI
PS C:\Users\anon> dir S:\EFI\debian
```

### Rewrite the Windows Boot Manager
```
PS C:\Users\anon> bcdboot C:\Windows /s S: /f UEFI
```
Boot files successfully created.

control the entries
```
PS C:\Users\anon> bcdedit /enum firmware
```
\EFI\Microsoft\Boot\bootmgfw.efi

### Remove Grub Boot Manager
```
PS C:\Users\anon> Remove-Item -Path "S:\EFI\debian" -Recurse -Force
```
check if it's gone
```
PS C:\Users\anon> Get-ChildItem S:\EFI
```
### Next, we'll remove the GRUB firmware entry from the UEFI NVRAM.
list Firmware boot entries
```
PS C:\Users\anon> bcdedit /enum firmware
```
shows
```
Firmware Application (101fffff)
--------------------------------
identifier              {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
description             debian
path                    \EFI\debian\shimx64.efi
```
remove the debian {identifier}
```
PS C:\Users\anon> bcdedit /delete "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
```
quick check if it was successfull
```
PS C:\Users\anon> bcdedit /enum firmware
```

### Remove the temporary drive letter and reboot
```
PS C:\Users\anon> diskpart
```
```
DISKPART> list volume
DISKPART> select volume 4
DISKPART> remove letter=s
DISKPART> exit
```

```
PS C:\Users\anon> Restart-Computer -Force
```







