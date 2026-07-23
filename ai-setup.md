## Preparations
minimum 2GB USB drive to the Debian Net Installer
Download -> https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso
Download Rufus -> https://github.com/pbatard/rufus/releases/download/v4.15/rufus-4.15p.exe

## Prepare Boot Drive with Rufus
Partition: GPT
Target: UEFI
Writemode: ISO-Image

## Boot into Bootmanager
WS WRX90E-SAGE SE 
Press F8 to enter Boot menue

## Start install
Choose either
Graphical install or Install (the result is the same)

## Configure lang settings
Language:         Deutsch
Location:         Deutschland
Locales:          de_DE.UTF-8
Keyboard:         Deutsch

## Configure Hostname
Hostname cgn-trp
Domain local

## Create User
Root User -> empty leads to the situation that the first created user is member of the sudo-group (safety)
New User -> dave
Password -> *********

## Cerate Partitions
Partition Manager -> Manual
select the correct drive -> e.g. SCSI8 (0,0,0) (sda) 1.0TB INTEL SS DSCKKW010X6
1GB 	EFI-Systempartition /boot/efi
100GB	ext4				/
899GB	ext4				/home
no swap needed!

control twice! -> end partioning and write to drive

## Configure Paketmanager
Country: Germany
Server: deb.debian.org
Proxy: empty

## DPKG popularity-contest (telemetry)
-> no 

## Software selection
no GUI
Select only
[x] SSH server
[x] standard system utilities

## Configure Bootloader
debian will configure it automatically no need to do it manually

## Boot into the new system
while boot press F8 and select debian

cgn-trp login: dave
Password: *******

## Upgrade the system
sudo apt update
sudo apt full-upgrade -y
sudo reboot

## Check Debian version
cat /etc/os-release
>> PRETTY_NAME="Debian GNU/Linux 13 (trixie)"

## Check Kernel Version
uname -a
>> Linux cgn-trp 6.12.96+deb13-amd64

## Check Arch
dpkg --print-architecture
>> amd64

## Configure APT-Sources
Components: main contrib non-free non-free-firmware
sudo nano /etc/apt/sources.list
sudo apt update

## Install Frimware und Microcode
lscpu | grep "Vendor ID"
>> AuthenticAMD
sudo apt install -y amd64-microcode firmware-linux firmware-linux-nonfree
sudo update-initramfs -u

## Install base software
Sudo apt install -y curl wget git htop btop tmux tree jq unzip zip rsync smartmontools nvme-cli pciutils usbutils lshw lm-sensors ca-certificates gnupg openssl build-essential dkms linux-headers-amd64 kmod mokutil

## Connect via SSH
hostname -I
ssh dave@192.168.0.238

## SSH Hardening
WIP

## Prepare the System for AI usage
sudo apt install -y python3 python3-pip python3-venv nvtop nvidia-driver firmware-misc-nonfree
sudo reboot

## Install NVIDIA Driver and CUDA toolkit
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

wget https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
apt-cache policy nvidia-open
apt-cache policy cuda-drivers
sudo apt install -y nvidia-open
sudo reboot
lsmod | grep nvidia
nvidia-smi
sudo apt install -y cuda-toolkit
cat <<'EOF' >> ~/.bashrc

# NVIDIA CUDA
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
EOF
source ~/.bashrc

nvidia-smi
nvcc --version
