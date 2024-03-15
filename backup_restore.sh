#!/bin/bash 

backup_dirs="/root /home /etc /usr/local /opt /srv /var/lib /var/mail /var/www /var/backups /var/spool/cron/crontabs /var/local /var/opt /var/log"   
options="-aAXvR --delete" 

# backup function 
# run by the host to be backed up 
backup() {
    # remind to write a brief note for this backup 
    echo -n "Have you written the backup note yet? (y/n): "
    read answer 
    if [[ $answer == 'N' || $answer == 'n' ]]; then 
        # no
        echo "Ok, canceled"
        exit 1
    fi 

    # destination location 
    # set root@example as the backing up server 
    destination="root@example:/var/local/backups/$(hostname)/$(date +%Y-%m-%d-%T)"

    # DRY-RUN: backing up
    rsync --dry-run $options $backup_dirs  $destination 

    echo "This is only a DRY-RUN Test, not a real backup!"
    echo -n "Do you want to back it all up for real? (y/n): "
    read answer 
    if [[ $answer == 'N' || $answer == 'n' ]]; then 
        # no
        echo "Ok, canceled"
        exit 1
    fi 

    # back it all up for real
    rsync $options $backup_dirs  $destination 
}

# restore function 
# run by the host at which the backups are located 
restore() {
    echo -n "Please specify your FQDN hostname which you'd like to restore: "
    read hostname 
    
    echo -n "Please specify the name(date) of directory under which your backup is in: "
    read date 

    source="/var/local/backups/$hostname/$date"
    destination="root@$hostname:/"

    for path in $backup_dirs; do 
        path="$source/./$path"
        paths+=("$path")
    done 

    # DRY-RUN test 
    rsync --dry-run $options ${paths[@]} $destination 

    echo "This is only a DRY-RUN Test, not a real backup!"
    echo -n "Do you want to restore it all up for real? (y/n): "
    read answer 
    if [[ $answer == 'N' || $answer == 'n' ]]; then 
        # no
        echo "Ok, canceled"
        exit 1
    fi 

    # restore it all up for real
    rsync $options ${paths[@]} $destination 
}

main() {
    # check if it is run by root 
    if [[ $(whoami) != 'root' ]]; then 
        # not root 
        echo "Must be executed by root only"
        exit 1
    fi 

    echo -ne "Please select the function you would like to perform \n1. backup \n2. restore \nYour selection: "
    read answer 
    if [[ $answer -eq 1 ]]; then 
        # backup 
        backup
    elif [[ $answer -eq 2 ]]; then 
        # restore 
        restore
    else 
        echo "exit"
    fi 
}

main 