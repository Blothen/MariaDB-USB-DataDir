#!/usr/bin/env bash
#SOURCE ENV AND SCRIPTS
#Ciarán Johnson 2023
#Photo Experience
source ./config.env # Source Config

#  __  __            _       _____  _____     _____           _       _   
# |  \/  |          (_)     |  __ \|  __ \   / ____|         (_)     | |  
# | \  / | __ _ _ __ _  __ _| |  | | |  | | | (___   ___ _ __ _ _ __ | |_ 
# | |\/| |/ _` | '__| |/ _` | |  | | |  | |  \___ \ / __| '__| | '_ \| __|
# | |  | | (_| | |  | | (_| | |__| | |__| |  ____) | (__| |  | | |_) | |_ 
# |_|  |_|\__,_|_|  |_|\__,_|_____/|_____/  |_____/ \___|_|  |_| .__/ \__| v0.0.5
#                                                              | |        
#                                                              |_|        
#   V0.0.1 Inital development, trial and error period
#   V0.0.2 remade code using functions instead of a long list of commands
#   V0.0.3 added mount existing usb
#   V0.0.4 added logging to log file also cleaned up the code
#   V0.0.5 Minor but important feature, make sure the script doesn't format the,
#          root partition incase of a config error.
#
#
function check_return_status { #check the return status of all_check_if_folder_exists, i pass an arbitraury number in.
    all_check_if_folder_exists 20
    if [ "$?" -eq 0 ]; then #if the return signal = 0 the USB contains mysql, or atleast i assume so
        echo "USB Contains MYSQL."
        me_script || exit #Launch the MYSQL EXIST SCRIPT in me.sh, wanted it in the same file but no wont work
    else
        echo "USB Doesnt contain MYSQL,." # If all fails launch the MYSQL DOESNT EXIST SCRIPT
        mde_script || exit
fi
}

function check_if_root_directory {
    if [ -d "home" ]; then
        echo "Wrong partition selected, this is the root partition, aborting not to overwrite data"
        exit 1
    elif [ -d "overlay" ]; then
        echo "Wrong partition selected, this is the boot partition, aborting not to overwrite data"
        exit 1
    else
        echo "Not using root directory, well done!"
    fi
}

# this is the MYSQL DOESNT EXIST SCRIPT
function mde_script {
    all_check_if_installed || exit
    all_kill_mariadb || exit
    sudo umount /dev/$partition
    sudo mkfs -t ext4 /dev/$partition
    sudo mkdir $mount_directory
    sudo mount /dev/$partition $mount_directory
    all_generate_fstab || exit
    sudo mkdir /mnt/phoexdata/mysql/
    sudo cp -r -v $maria_db_data_directory /mnt/phoexdata/
    sudo chown -R mysql:mysql /mnt/phoexdata/mysql/
    all.copy_config || exit
    all_start_mariadb || exit
}

# This is the MYSQL DOES EXIST SCRIPT
function me_script {
    all_check_if_installed || exit
    all_kill_mariadb || exit
    all_generate_fstab || exit
    all.copy_config || exit
    sudo chown -R mysql:mysql $mount_directory/mysql/
    all_start_mariadb || exit
}

#Shared functions
function all_check_if_installed { #Update and upgrqde and double check MariaDB is installed
    sudo apt-get update
    sudo apt-get install mariadb-server -y
}

function all_check_if_folder_exists { # Check directory exists, kinda how im guessing if its been done before
    sudo umount /dev/$partition
    sudo mount /dev/$partition $mount_directory # why would that exact folder exist if it wasnt done before anyways
    if [ -d $check_directory ];                 #Returns either 0 or 1 which will determine which script will be ran
        then                                    #Also looks at file system of USB if the folder exists to see if EXT4
            echo "Directory exists." 
            result=$(sudo file -Ls /dev/$partition)
            fstype=$(echo "$result" | tr ' ' '\n' | grep ext4)
            echo $fstype
            if [ $fstype != "ext4" ];
            then
                echo "Wrong Filesystem pressent"
            else
                echo "USB is ext4, proceeding"
                return 0
            fi
        else
            echo "Directory does not exist."
            return 1
fi
}

function all_generate_fstab { #Generate UUID of the usb and check if it exists in the fstab, if it doesnt, tee it into fstab
    usb_uuid="$($partition)"
    if ! grep -q "$usb_uuid" /etc/fstab ; then
        echo '# MariaUSB' | sudo tee -a /etc/fstab
        echo "UUID=$usb_uuid    $mount_directory    ext4    defaults,nofail    0    1" | sudo tee -a /etc/fstab
        echo "fstab generated for $usb_uuid"
    fi
}

function all_start_mariadb { # reload the systemctl daemon, this was for a deprectated featured
    sudo systemctl daemon-reload # start the service
    sudo systemctl start mariadb.service
    sudo systemctl status mariadb.service
}

function all_kill_mariadb {
    sudo systemctl stop mariadb.service
}

function all.copy_config {
    sudo rm -rf /etc/mysql/mariadb.conf.d/50-server.cnf
    sudo touch /etc/mysql/mariadb.conf.d/50-server.cnf
    echo "#Created by MariaDD on $(date +'%r/%m/%d/%Y')" | sudo tee -a /etc/mysql/mariadb.conf.d/50-server.cnf
    echo "$(<50-server.cnf)" | sudo tee -a /etc/mysql/mariadb.conf.d/50-server.cnf
}

function all.check_config_empty {
    if [ -s "config.env" ]; then
        echo "Config is not empty"
        check_return_status || exit # CALL the check_return_status
    else
        echo "Config is empty"
        exit 1
    fi
}

# Function to log script output to a log file
log_output() {
    local log_file="script.log"
    exec &> >(tee -a "$log_file")
    echo "Script started at $(date +'%r/%m/%d/%Y')" >> "$log_file"
    check_if_root_directory || exit
    all.check_config_empty || exit # CALL the check_config_empty
    echo "Script ended at $(date +'%r/%m/%d/%Y')" >> "$log_file"
}

# Call the log_output function
log_output
