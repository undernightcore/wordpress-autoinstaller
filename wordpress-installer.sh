#!/bin/bash

function check_root {
    echo "INFO: Checking priviledges..."
    if [ $UID -ne 0 ]
    then
        echo "ERROR: Please, run as root!"
        exit 1
    else
        return 0
    fi
}

function check_connectivity {
    echo "INFO: Checking connection..."
    wget -q --spider http://google.com
    if [ $? -eq 0 ]
    then
        return 0
    else
        echo "ERROR: Please, check your connection to the internet!"
        exit 1
    fi
}

function check_installed {
    #Using dpkg to check what is already installed
    dpkg --get-selections | grep $1 &> /dev/null
    return $?
}

function installer {
    apt install -y $1 &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "ERROR: Couldn't install $1"
        exit 1
    else
        echo "OK: $1 installed!"
        return 0
    fi
}

function install_dependencies {
    #Programs to install
    programs=(apache2 php php-mysql libapache2-mod-php php-cli php-cgi php-gd mariadb-server mariadb-client)
    #Install
    for program in $programs
    do
        check_installed $program
        if [ $? -ne 0 ]
        then
            installer $program
        else
            echo "OK: $program is already installed. Skipping..."
        fi
    done
}

function check_apache {
    echo "INFO: Checking apache2..."
    if [ $(ls -a | wc -l) -ne 3 ]
    then
        while true
        do
            echo "IMPORTANT: Your apache2 directory (/var/www/html) isn't empty!"
            echo -n "IMPORTANT: Do you want to empty it now? (Y/N): "
            read choice
            case $choice in
                y | Y)
                echo "INFO: Removing all data from /var/www/html ..."
                rm -r /var/www/html/*
                break
                ;;
                n | N)
                echo "INFO: Exiting..."
                exit 1
                ;;
                *)
                echo "ERROR: Please, choose an option..."
                ;;
            esac
        done
    else
        rm -r /var/www/html/*
    fi
    echo "OK: Apache2 directory is ready!"
}
