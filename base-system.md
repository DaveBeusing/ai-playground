# Debian 13.6 (trixie) minimal base system
> A USB flash drive with a capacity of at least 2 GB is required.

download Rufus 4.15 portable
```
https://github.com/pbatard/rufus/releases/download/v4.15/rufus-4.15p.exe
```

download Debian 13.6 NetInstall iso
```
https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso
```

run Rufus and prepare USB flash drive
> Partition: GPT

> Target: UEFI

> Writemode: ISO-Image


boot into boot manager
> WS WRX90E-SAGE SE 
```
Press F8 during the boot process to select the boot device
```

## installing the base system on a NMVe drive
Choose either Graphical install or install 

(the result is the same)

### configure lang settings 

(in my case)
> Language:         Deutsch

> Location:         Deutschland

> Locales:          de_DE.UTF-8

> Keyboard:         Deutsch

### configure Hostname
Hostname
> cgn-trp

Domain
> local


### create User
Root User -> empty leads to the situation that the first created user is member of the sudo-group (safety)

> New User

> Password


### create Partitions
> Partition Manager -> Manual

select the correct drive -> e.g. SCSI8 (0,0,0) (sda) 1.0TB INTEL SS DSCKKW010X6

```
1GB 	EFI-Systempartition /boot/efi
100GB	ext4				/
899GB	ext4				/home
```

**no swap needed!**

**control twice! -> end partioning and write to drive**

### configure packet manager 
(in my case)
> Country: Germany

> Server: deb.debian.org

> Proxy: empty

### DPKG popularity-contest (telemetry)
> no 

## Software selection
> no GUI

Select only
```
[x] SSH server
[x] standard system utilities
```


## configure Bootloader
~~debian will configure it automatically no need to do it manually~~

we need to do it manually to ensure that Grub is installed on the same drive

**WIP:** add explanations regarding the installation

An installation of GRUB on the wrong SSD for example, one containing an internal Windows installation, can be undone as follows:

[**Undo Grub installation**](grub-setup.md#undo-grub-installation)

## boot into the new system
> WS WRX90E-SAGE SE 
```
Press F8 during the boot process to select the boot device
```

```
cgn-trp login: <username>
Password: *******
```

## upgrade the system
```
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

> WS WRX90E-SAGE SE 
```
Press F8 during the boot process to select the boot device
```



### check Debian version
```
cat /etc/os-release
```
>> PRETTY_NAME="Debian GNU/Linux 13 (trixie)"

### check kernel version
```
uname -a
```
>> Linux cgn-trp 6.12.96+deb13-amd64

### check arch
```
dpkg --print-architecture
```
>> amd64

### configure APT-Sources
```
sudo nano /etc/apt/sources.list
```
add Components
```
main contrib non-free non-free-firmware
```
update apt package manager
```
sudo apt update
```


### install Firmware und Microcode
```
lscpu | grep "Vendor ID"
```
>> AuthenticAMD

```
sudo apt install -y amd64-microcode firmware-linux firmware-linux-nonfree
sudo update-initramfs -u
```


# install base software
```
sudo apt install -y curl wget git htop btop tmux tree jq unzip zip rsync smartmontools nvme-cli pciutils usbutils lshw lm-sensors ca-certificates gnupg openssl build-essential dkms linux-headers-amd64 kmod mokutil
```
**WIP:** rethink the base set of packages

### connect via SSH
get the local IP address of the system
```
hostname -I
```
>>192.168.0.238

now we can access our system via SSH from another computer.
```
ssh <username>@192.168.0.238
```
**WIP:** SSH hardening

### prepare the system for AI usage
```
sudo apt install -y python3 python3-pip python3-venv nvtop nvidia-driver firmware-misc-nonfree
```
```
sudo reboot
```


## install NVIDIA Driver and CUDA toolkit
deactivate/blacklist the standard nouveau video driver

```
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
```

**WIP:** add the current path we use
```
wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
```
```
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
apt-cache policy nvidia-open
apt-cache policy cuda-drivers
sudo apt install -y nvidia-open
```

```
sudo reboot
```
> WS WRX90E-SAGE SE 
```
Press F8 during the boot process to select the boot device
```

```
lsmod | grep nvidia
nvidia-smi
sudo apt install -y cuda-toolkit
```

```
cat <<'EOF' >> ~/.bashrc

# NVIDIA CUDA
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
EOF
```

reload bash
```
source ~/.bashrc
```

check SMI/NVCC install
```
nvidia-smi
nvcc --version
```

