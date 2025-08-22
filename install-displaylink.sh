#!/bin/bash

# ==============================================================================
# A robust script to install or uninstall DisplayLink drivers on Ubuntu-based
# systems.
#
# Author: Thugney
# Version: 2.0
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Return value of a pipeline is the value of the last command to exit with a
# non-zero status.
set -o pipefail

# --- Constants ---
DRIVER_URL="https://www.synaptics.com/sites/default/files/Ubuntu/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu5.8-EXE.zip"
LOG_FILE="/var/log/displaylink-installer.log"
UNINSTALLER_PATH="/usr/bin/displaylink-uninstall"

# --- Functions ---

# Logging function to print to both console and log file
log() {
    # The `tee -a` command appends the output to the log file.
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Displays usage information
usage() {
    echo "Usage: $(basename "$0") [OPTION]"
    echo "A script to manage DisplayLink drivers on Ubuntu-based systems."
    echo
    echo "Options:"
    echo "  --install    Install the DisplayLink driver (default action)."
    echo "  --uninstall  Uninstall the DisplayLink driver."
    echo "  --help       Display this help and exit."
    echo
    echo "This script must be run with root privileges (e.g., sudo)."
    exit 0
}

# Checks for root privileges
check_root() {
    # $EUID is the "Effective User ID", which is 0 for the root user.
    if [[ "$EUID" -ne 0 ]]; then
        log "\e[31m❌ Error: This script must be run as root. Please use 'sudo'.\e[0m"
        exit 1
    fi
}

# Installs necessary dependencies using apt
install_dependencies() {
    log "\e[34m[*] Installing necessary dependencies (dkms, libdrm-dev, unzip)...\e[0m"
    apt-get update
    apt-get install -y dkms libdrm-dev unzip
    log "\e[32m[✔] Dependencies installed successfully.\e[0m"
}

# Main installation logic
do_install() {
    if [ -f "$UNINSTALLER_PATH" ]; then
        log "\e[33m[!] DisplayLink driver already appears to be installed. To reinstall, please uninstall first.\e[0m"
        exit 1
    fi

    install_dependencies

    # Create a secure temporary directory.
    # The 'trap' command ensures the 'cleanup' function is run on script exit.
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'cleanup' EXIT

    cleanup() {
        log "\e[34m[*] Cleaning up temporary files...\e[0m"
        rm -rf "$temp_dir"
        log "\e[32m[✔] Cleanup complete.\e[0m"
    }

    log "\e[34m[*] Downloading DisplayLink driver from Synaptics...\e[0m"
    wget -O "$temp_dir/displaylink.zip" "$DRIVER_URL"
    log "\e[32m[✔] Download complete.\e[0m"

    log "\e[34m[*] Extracting the driver archive...\e[0m"
    unzip "$temp_dir/displaylink.zip" -d "$temp_dir"

    # Find the installer file, as its name might change with new versions.
    local installer_file
    installer_file=$(find "$temp_dir" -type f -name 'displaylink-driver-*.run')

    if [ -z "$installer_file" ]; then
        log "\e[31m❌ Error: Could not find the .run installer file in the archive.\e[0m"
        exit 1
    fi

    log "\e[34m[*] Making the installer executable...\e[0m"
    chmod +x "$installer_file"

    log "\e[34m[*] Running the DisplayLink installer. Please follow its prompts...\e[0m"
    # The installer itself will handle the rest of the installation
    "$installer_file"

    log "\e[32m[✔] Installation script finished successfully!\e[0m"
    log "\e[33m[!] A system reboot is required for the changes to take effect.\e[0m"
}

# Main uninstallation logic
do_uninstall() {
    if [ ! -f "$UNINSTALLER_PATH" ]; then
        log "\e[33m[!] DisplayLink driver does not appear to be installed. Nothing to do.\e[0m"
        exit 0
    fi

    log "\e[34m[*] Running the DisplayLink uninstaller...\e[0m"
    # The uninstaller is interactive, so we run it directly for the user
    "$UNINSTALLER_PATH"

    log "\e[32m[✔] Uninstallation complete.\e[0m"
    log "\e[33m[!] A reboot is recommended to ensure all components are unloaded.\e[0m"
}

# --- Main Logic ---
main() {
    # Initialize log file for this run
    echo -e "\n--- DisplayLink Manager Log: $(date) ---" > "$LOG_FILE"
    
    check_root

    # Default action is 'install' if no arguments are given
    local action="install"

    # Simple argument parsing
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --install)
                action="install"
                ;;
            --uninstall)
                action="uninstall"
                ;;
            --help)
                usage
                ;;
            *)
                log "\e[31m❌ Error: Invalid option '$1'. Use --help for usage information.\e[0m"
                exit 1
                ;;
        esac
    fi

    log "\e[34m[*] Action selected: $action\e[0m"

    if [[ "$action" == "install" ]]; then
        do_install
    elif [[ "$action" == "uninstall" ]]; then
        do_uninstall
    fi
}

# --- Run Script ---
# Pass all script arguments to the main function
main "$@"
