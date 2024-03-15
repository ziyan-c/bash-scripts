#!/bin/bash 

# For ubuntu only

# 1. check if it is run by root 
# 2. update and upgrade 
# 3. install necessary softwares 
# 4. mask AppArmor 
# 5. mask UFW 
# 6. set hostname 
# 7. enable BBR
# 8. change root password to randomly generated password 
# 9. add SSH public key to root 
# 10. modify SSH config: disable password logining, allow root logining 
# 11. turn on firewalld: disabling(masking) iptables, ip6tables and ebtables
# 12. Set up Swap file 
# 13. Generate SSH key-pair 

# IMPORTANT 
# Variables you need to know beforehand: 
# Hostname 
# NIC name 
# Swap file size 


# 1
# check if it is run by root 
check_user() {
    if [[ $(id -u) -ne 0 ]]; then
        # not root 
        echo "This script is only executable by root"
        exit 1
    fi
}

# 2
# update and upgrade 
update_upgrade() {
    apt update 
    apt upgrade -y 
}

# 3
# install softwares 
install_softwares() {
    apt install coreutils -y
    apt install nmap -y 
    apt install net-tools -y 
    apt install screen -y 
    apt install openssl -y 
}

# 4 
# turn off and mask AppArmor 
mask_apparmor() {
    systemctl disable apparmor 
    systemctl stop apparmor 
    systemctl mask apparmor 
}

# 5
# turn off and mask UFW
mask_ufw() {
    systemctl disable ufw 
    systemctl stop ufw 
    systemctl mask ufw
}


# 6
# set up hostname 
set_hostname() {    
    # $hostname 
    echo -n "Please specify your hostname: "
    read hostname 

    echo -n $hostname > /etc/hostname 
}

# 7
# enable BBR 
enable_bbr() {
    # no number prefix needed as stated in README 
    sysctl_bbr_file=/etc/sysctl.d/my_local.conf 

    echo "net.core.default_qdisc = fq" >> $sysctl_bbr_file
    echo "net.ipv4.tcp_congestion_control = bbr" >> $sysctl_bbr_file 
}



# 8
# change root password to randomly generated password 
change_root_password() {
    # randomly generate a 16-character long password 
    root_password=$(openssl rand -base64 16)
    # assign password to root
    usermod --password $(echo -n $root_password | openssl passwd -stdin) root 

    echo -e "Your New Root Password is $root_password \n"
}

# 9
# add ssh public key to root
add_ssh_public_key() {
    echo -n "Please specify your SSH public key file location: "
    read ssh_public_key_location

    mkdir /root/.ssh 
    cat $ssh_public_key_location >> /root/.ssh/authorized_keys 
}

# 10 
# modify sshd config
# disable password loging & allow root logining 
modify_sshd_config() {
    # the number '00-' does matter here, it specifies the priority of execution 
    sshd_config_file=/etc/ssh/sshd_config.d/00-my_local.conf 

    echo "PasswordAuthentication no" >> $sshd_config_file
    echo "PermitRootLogin yes" >> $sshd_config_file 
}

# 11
# turn on firewalld 
turnon_firewalld() {
    # mask iptables, ip6tables and ebtables 
    systemctl mask iptables
    systemctl mask ip6tables
    systemctl mask ebtables

    apt install firewalld -y 
    systemctl unmask firewalld 
    systemctl enable firewalld 
    systemctl restart firewalld 

    # $nic_name 
    echo -n "Please specify your NIC name: "
    read nic_name 

    # Add NIC to firewalld 
    firewall-cmd --permanent --add-interface=$nic_name
    systemctl restart firewalld 
}

# 12 
# set up Swap File 
setup_swapfile() {
    swapfile_location=/var/local/swapfile 

    echo -n "Please specify how many MB you'd like to allocate for this Swap File: "
    read swapfile_size

    # bs = 1048576 Bytes = 1 M Bytes 
    dd if=/dev/zero of=$swapfile_location bs=1048576 count=$swapfile_size 

    chown root:root $swapfile_location
    chmod 600 $swapfile_location

    mkswap $swapfile_location
    swapon $swapfile_location

    echo "$swapfile_location     swap      swap        defaults        0       0" >> /etc/fstab
}

# 13. Generate SSH key-pair 
generate_ssh_keypair() {
    echo "Generating SSH key-pair"
    ssh-keygen -t rsa -b 4096
}

# ending message 
ending_message() {
    echo -e "\n\n"

    echo "All finished!"
    echo "Please consider rebooting your host"
}

main() {
    check_user

    echo "1. update and upgrade "
    echo "2. install necessary softwares "
    echo "3. mask AppArmor "
    echo "4. mask UFW "
    echo "5. set hostname "
    echo "6. enable BBR"
    echo "7. change root password to randomly generated password "
    echo "8. add SSH public key to root "
    echo "9. modify SSH config: disable password logining, allow root logining "
    echo "10. turn on firewalld: disabling(masking) iptables, ip6tables and ebtables"
    echo "11. Set up Swap file "
    echo "12. Generate SSH key-pair "
    echo "13. ALL AT ONCE"

    echo -n "Your selection: "
    read option 

    case $option in 
    1)
        update_upgrade
        ;;
    2)
        install_softwares
        ;;
    3)
        mask_apparmor
        ;;
    4)
        mask_ufw
        ;;
    5)
        set_hostname
        ;;
    6)
        enable_bbr
        ;;
    7)
        change_root_password
        ;;
    8)
        add_ssh_public_key
        ;;
    9)
        modify_sshd_config
        ;;
    10)
        turnon_firewalld
        ;;
    11)
        setup_swapfile
        ;;
    12)
        generate_ssh_keypair
        ;;
    13)
        update_upgrade
    
        install_softwares
    
        mask_apparmor
     
        mask_ufw
    
        set_hostname
    
        enable_bbr
      
        change_root_password
   
        add_ssh_public_key
    
        modify_sshd_config
   
        turnon_firewalld
   
        setup_swapfile
    
        generate_ssh_keypair
        ;;
    esac 

    ending_message
}

main













