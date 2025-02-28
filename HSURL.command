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

# Set up our url
url="http://swscan.apple.com/content/catalogs/others/index-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"

function get_current() {
    # Try to get our current variable state
    current="$(/usr/sbin/nvram IASUCatalogURL 2>/dev/null)"
    if [ -z "$current" ]; then
        return
    fi
    # We got something - try to strip IASUCatalogURL\t from it
    echo "${current/IASUCatalogURL	/}"
}

function main () {
    # Try to get our current variable state
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
    message=
    if [ ! -e "/usr/bin/sw_vers" ] || [ ! -e "/usr/bin/cut" ]; then
        message="Could not verify OS version!\n\nMissing required cli tools to check (sw_vers, cut)."
    else
        # Gather info about the currently running OS version
        name="$(sw_vers --productName)"
        prod="$(sw_vers --productVersion)"
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

verify_os
main
