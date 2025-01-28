#!/bin/bash

# Path to info file
info_file="./info.private"

# 1. Load configuration using grep
load_info_file() {
    if [[ ! -f "$info_file" ]]; then
        echo "Error: Info file $info_file not found!"
        exit 1
    fi

    # Extract variables using grep
    hostname=$(grep '^hostname=' "$info_file" | cut -d'=' -f2-)
    nic_name=$(grep '^nic_name=' "$info_file" | cut -d'=' -f2-)
    ssh_public_key_personal=$(grep '^ssh_public_key_personal=' "$info_file" | cut -d'=' -f2-)
    ssh_public_key_server=$(grep '^ssh_public_key_server=' "$info_file" | cut -d'=' -f2-)
    swapfile_size=$(grep '^swapfile_size=' "$info_file" | cut -d'=' -f2-)
}

# 2. Check if the script is run by root
check_user() {
    if [[ $(id -u) -ne 0 ]]; then
        echo "This script is only executable by root"
        exit 1
    fi
}

# 3. Update and upgrade system
update_upgrade() {
    apt update && apt upgrade -y
}

# 4. Install necessary software
install_softwares() {
    apt install coreutils nmap net-tools screen openssl traceroute curl vim -y
    apt install -y wireguard-tools 
}

# 5. Disable and mask AppArmor
mask_apparmor() {
    systemctl disable apparmor
    systemctl stop apparmor
    systemctl mask apparmor
}

# 6. Disable and mask UFW
mask_ufw() {
    systemctl disable ufw
    systemctl stop ufw
    systemctl mask ufw
}

# 7. Set hostname
set_hostname() {
    if [[ -z "$hostname" ]]; then
        echo "Error: 'hostname' not specified in $info_file"
        exit 1
    fi

    echo "$hostname" > /etc/hostname
}

# 8. Enable BBR
enable_bbr() {
    sysctl_bbr_file="/etc/sysctl.d/my_local.conf"

    echo "net.core.default_qdisc = fq" >> $sysctl_bbr_file
    echo "net.ipv4.tcp_congestion_control = bbr" >> $sysctl_bbr_file
    sysctl --system
}

# 9. Add SSH public keys to root
add_ssh_public_key() {
    mkdir -p /root/.ssh

    echo "$ssh_public_key_personal" >> /root/.ssh/authorized_keys
    echo "$ssh_public_key_server" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
}

# 10. Modify SSHD configuration
modify_sshd_config() {
    sshd_config_file="/etc/ssh/sshd_config.d/00-my_local.conf"
    mkdir -p /etc/ssh/sshd_config.d

    echo "PasswordAuthentication no" > $sshd_config_file
    echo "PermitRootLogin yes" >> $sshd_config_file

    systemctl restart sshd
}

# 11. Enable and configure firewalld
turnon_firewalld() {
    apt install firewalld -y
    systemctl unmask firewalld
    systemctl enable firewalld
    systemctl restart firewalld

    if [[ -z "$nic_name" ]]; then
        echo "Error: 'nic_name' not specified in $info_file"
        exit 1
    fi

    firewall-cmd --permanent --add-interface="$nic_name"
    systemctl restart firewalld
}

# 12. Set up swap file
setup_swapfile() {
    swapfile_location="/var/local/my_swapfile"

    if [[ -z "$swapfile_size" ]]; then
        echo "Error: 'swapfile_size' not specified in $info_file"
        exit 1
    fi

    dd if=/dev/zero of=$swapfile_location bs=1M count="$swapfile_size" status=progress
    chmod 600 $swapfile_location
    mkswap $swapfile_location
    swapon $swapfile_location
    echo "$swapfile_location swap swap defaults 0 0" >> /etc/fstab
}

# 13. Change root password
change_root_password() {
    root_password=$(openssl rand -base64 20)
    echo "root:$root_password" | chpasswd
}

# 14. Add aliases to bashrc
add_aliases() {
    echo "export LS_OPTIONS='--color=auto'" >> /root/.bashrc
    echo "alias ls='ls \$LS_OPTIONS'" >> /root/.bashrc
    echo "alias ll='ls \$LS_OPTIONS -l'" >> /root/.bashrc
}

# 15. Limit journald log size
limit_journald_log_file_size() {
    echo "SystemMaxUse=500M" >> /etc/systemd/journald.conf
    systemctl restart systemd-journald
}

# 16. Display ending message
ending_message() {
    echo -e "\n\nAll done!"
    echo "Your New Root Password is $root_password"
    echo -e "\nThings to do:"
    echo "Reboot your system"
}

# 17. Main function to run all tasks
main() {
    load_info_file
    check_user
    update_upgrade
    install_softwares
    mask_apparmor
    mask_ufw
    set_hostname
    enable_bbr
    add_ssh_public_key
    modify_sshd_config
    turnon_firewalld
    setup_swapfile
    change_root_password
    add_aliases
    limit_journald_log_file_size
    ending_message
}

# Execute the script
main
