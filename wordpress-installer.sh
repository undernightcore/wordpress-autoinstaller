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
    apt-get install -y $1 &> /dev/null
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
    echo "INFO: Updating repositories..."
    apt-get update &> /dev/null
    for program in ${programs[@]}
    do
        check_installed $program
        if [ $? -ne 0 ]
        then
            installer $program
        else
            echo "OK: $program is already installed. Skipping..."
        fi
    done
    echo "OK: All services installed!"
}

function check_apache {
    echo "INFO: Checking apache2..."
    if [ $(ls -a /var/www/html | wc -l) -ne 3 ]
    then
        while true
        do
            echo "IMPORTANT: Your apache2 directory (/var/www/html) isn't empty!"
            echo -n "IMPORTANT: Do you want to empty it now? (Y/N): "
            read choice
            case $choice in
                y | Y)
                echo "INFO: Removing all data from /var/www/html ..."
                rm -r /var/www/html/* &> /dev/null
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
        rm -r /var/www/html/* &> /dev/null
    fi
    echo "OK: Apache2 directory is ready!"
}

function setup_mariadb {
    echo "INFO: Configuring MariaDB..."
    #Ask password
    echo -n "IMPORTANT: Please, set a password for MySQL user: "
    read MYSQL_PASSWORD
    #Script for mysql_secure_installation
    mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_PASSWORD') WHERE User='root'"
    mysql -u root -p${MYSQL_PASSWORD} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -u root -p${MYSQL_PASSWORD} -e "DELETE FROM mysql.user WHERE User=''"
    mysql -u root -p${MYSQL_PASSWORD} -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
    mysql -u root -p${MYSQL_PASSWORD} -e "FLUSH PRIVILEGES"
    #Creating users and databases
    mysql -u root -p${MYSQL_PASSWORD} -e "CREATE DATABASE wordpress"
    mysql -u root -p${MYSQL_PASSWORD} -e "CREATE USER wordpress@localhost IDENTIFIED BY '$MYSQL_PASSWORD'"
    mysql -u root -p${MYSQL_PASSWORD} -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost"
    mysql -u root -p${MYSQL_PASSWORD} -e "FLUSH PRIVILEGES"
    echo "OK: MariaDB configured!"
}

function setup_wordpress {
    echo "INFO: Installing wordpress..."
    wget -q https://wordpress.org/latest.tar.gz -O /var/www/html/latest.tar.gz
    tar -C /var/www/html/ -zxvf /var/www/html/latest.tar.gz
    rm /var/www/html/latest.tar.gz
    cp -r /var/www/html/wordpress/* /var/www/html/
    rm -r /var/www/html/wordpress
    mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/wordpress/g" /var/www/html/wp-config.php
    sed -i "s/username_here/wordpress/g" /var/www/html/wp-config.php
    sed -i "s/password_here/${MYSQL_PASSWORD}/g" /var/www/html/wp-config.php
    chown -R www-data:www-data /var/www/html
    echo "OK: Wordpress installed!"
}

function start {
    base64 -d <<<"IF9fICAgICAgX18gICAgICAgICAgXyAgICAgICAgICAgICAgICAgICAgICBfX18gICAgICAgICBfICAgICAgICBfIF8gICAgICAgICAKIFwgXCAgICAvIC9fXyBfIF8gX198IHxfIF9fIF8gXyBfX18gX19fX19fIHxfIF98XyBfICBfX3wgfF8gX18gX3wgfCB8X19fIF8gXyAKICBcIFwvXC8gLyBfIFwgJ18vIF9gIHwgJ18gXCAnXy8gLV98Xy08Xy08ICB8IHx8ICcgXChfLTwgIF8vIF9gIHwgfCAvIC1fKSAnX3wKICAgXF8vXF8vXF9fXy9ffCBcX18sX3wgLl9fL198IFxfX18vX18vX18vIHxfX198X3x8Xy9fXy9cX19cX18sX3xffF9cX19ffF98ICAKICAgICAgICAgICAgICAgICAgICAgIHxffCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKCkJ5IEphdmllciBNYXJ0w60gVmFsY8OhcmNlbAotLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCklNUE9SVEFOVDogQSBjbGVhbiB1YnVudHUvZGViaWFuIGluc3RhbGxhdGlvbiBpcyByZWNvbW1lbmRlZC4KSU5GTzogRG8geW91IHdhbnQgdG8gc3RhcnQgdGhlIGluc3RhbGxhdGlvbiBub3c/IChZL04pOiA="
    read install_ready
    case $install_ready in
        y | Y)
            echo "INFO: Starting now..."
            ;;
        n | N)
            echo "INFO: Exiting..."
            exit 1
            ;;
        *)
            echo "ERROR: Please, choose a valid option..."
            exit 1
            ;;
    esac
}


function finishing {
    echo "DONE: It seems that everything just went fine! Please, try to connect via localhost or your local IP address. Thanks!"
    exit 0
}

#HERE THE SCRIPT ACTUALLY STARTS
start
check_root
check_connectivity
install_dependencies
check_apache
setup_mariadb
setup_wordpress
finishing
