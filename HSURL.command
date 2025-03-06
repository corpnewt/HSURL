#!/bin/bash

# Make sure we have the tools we need
if [ ! -e "/usr/sbin/nvram" ]; then
    echo "Missing nvram tool, cannot continue"
    exit 1
fi

nvram="/usr/sbin/nvram"
if [ -e "/usr/bin/sudo" ]; then
    # Recovery doesn't have sudo - but if we're
    # running locally - we'll need to prompt
    # for a password as needed.
    nvram="/usr/bin/sudo $nvram"
fi

# Set up our url and network check result
url="http://swscan.apple.com/content/catalogs/others/index-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
check_network="TRUE"
check_os="TRUE"
host="apple.com"
port=80
network_status="Connection Not Verified"

function print_help () {
    echo "usage: HSURL.command [-o] [-n] [-u URL] [-s HOST] [-p PORT]"
    echo
    echo "HSURL - a bash script to set or unset IASUCatalogURL to bypass HTTPS on 10.13"
    echo
    echo "optional arguments:"
    echo "  -h, --help              show this help message and exit"
    echo "  -o, --override-os       override the OS check for 10.13.x"
    echo "  -n, --skip-network      skips the check for a network connection"
    echo "  -u URL, --url URL       override the URL to use for IASUCatalogURL"
    echo "  -s HOST, --host HOST    override the apple.com host in the network check"
    echo "  -p PORT, --port PORT    override port 80 in the network check"
}

# Gather any passed arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) print_help; exit 0 ;;
        -o|--override-os) check_os="FALSE" ;;
        -n|--skip-network) check_network="FALSE"; network_status="Not Checked" ;;
        -u|--url) url="$2"; shift ;;
        -s|--host) host="$2"; shift ;;
        -p|--port) port="$2"; shift;;
        *) echo "Unknown parameter passed: $1"; print_help; exit 1 ;;
    esac
    shift
done

function verify_connection() {
    # Try to check if we have internet - warn if we appear not
    # to, and ask if the user wants to continue still.
    local message= nc=
    echo
    clear 2>/dev/null
    echo "# Checking For Network #"
    echo
    nc="/usr/bin/nc"
    # Make sure the command we need exists
    if [ ! -e "$nc" ]; then
        echo "Could not locate $nc! Skipping network check..."
        return
    fi
    # Actually run our network check - connect to port 80
    # to verify HTTP
    echo "$nc -zG 1 $host $port"
    $nc -zG 1 "$host" "$port" >/dev/null 2>&1
    if [ "$?" == "0" ]; then
        echo " - Succeeded"
        network_status="Connected"
        return
    fi
    echo " - Something went wrong"
    network_status="Connection Not Detected"
    # We appear to have network issues - warn, and ask if the
    # user wants to continue
    while true; do
        echo
        clear 2>/dev/null
        echo "# Network Connection Error #"
        echo
        echo "Could not detect an active network connection!"
        echo
        read -r -p "Do you wish to continue? [y/n]: " yn
        case $yn in
            [Yy]* ) break;;
            [NnQq]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

function get_current() {
    # Try to get our current variable state
    local current=
    current="$(/usr/sbin/nvram IASUCatalogURL 2>/dev/null)"
    if [ -z "$current" ]; then
        return
    fi
    # We got something - try to strip IASUCatalogURL\t from it
    echo "${current/IASUCatalogURL	/}"
}

function main () {
    # Try to get our current variable state
    local current=
    current="$(get_current)"
    echo
    clear 2>/dev/null
    echo "# High Sierra IASUCatalogURL #"
    echo
    if [ -z "$current" ]; then
        echo "Current: None Set"
    else
        echo "Current: $current"
    fi
    echo "Network: $network_status"
    echo
    echo "1. Set HTTP IASUCatalogURL (Pre-Install)"
    echo "2. Unset IASUCatalogURL    (Post-Install)"
    echo
    echo "Q. Quit"
    echo
    read -r -p "Please select an option: " menu
    if [ "$menu" == "1" ]; then
        # Set the var
        set_unset "$url"
    elif [ "$menu" == "2" ]; then
        # Unset the var
        set_unset
    elif [ "$menu" == "q" ] || [ "$menu" == "Q" ]; then
        # Quit
        exit
    fi
    main
}

function set_unset () {
    local target_url="$1"
    echo
    clear 2>/dev/null
    if [ -z "$target_url" ]; then
        echo "# Unsetting IASUCatalogURL #"
        comm="$nvram -d IASUCatalogURL"
    else
        echo "# Setting IASUCatalogURL #"
        comm="$nvram IASUCatalogURL="$target_url""
    fi
    echo
    echo $comm
    echo
    $comm
    if [ "$?" != "0" ]; then
        # Something went wrong - pause here
        echo
        read -r -p "Press [enter] to return..."
    fi
}

function verify_os () {
    local message=
    if [ ! -e "/usr/bin/sw_vers" ] || [ ! -e "/usr/bin/cut" ]; then
        message="Could not verify OS version!\n\nMissing required cli tools to check (sw_vers, cut)."
    else
        # Gather info about the currently running OS version
        name="$(sw_vers -productName)"
        prod="$(sw_vers -productVersion)"
        # Check if we're running High Sierra (10.13)
        major="$(echo "$prod" | /usr/bin/cut -d "." -f1)"
        minor="$(echo "$prod" | /usr/bin/cut -d "." -f2)"
        if [ "$major" != "10" ] || [ "$minor" != "13" ]; then
            message="Currently running "$name" "$prod"."
        fi
    fi
    if [ -z "$message" ]; then
        return
    fi
    while true; do
        echo
        clear 2>/dev/null
        echo "# Detected OS Error #"
        echo
        echo "This script expects you to be running macOS 10.13.x!"
        echo
        echo -e "${message}"
        echo
        read -r -p "Do you wish to continue? [y/n]: " yn
        case $yn in
            [Yy]* ) break;;
            [NnQq]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

if [ "$check_os" == "TRUE" ]; then
    verify_os
fi
if [ "$check_network" == "TRUE" ]; then
    verify_connection
fi
main
