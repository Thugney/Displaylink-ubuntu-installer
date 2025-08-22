#!/bin/bash

# DisplayLink Auto Installer for Ubuntu
# Automated script to install DisplayLink drivers on Ubuntu systems
# Compatible with Ubuntu 20.04+ including development versions like 25.04
#
# Author: Thugney
# License: MIT
# Version: 1.0.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/displaylink-install.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root directly."
        print_status "Run as regular user - the script will use sudo when needed."
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu_version() {
    if ! command -v lsb_release &> /dev/null; then
        print_warning "lsb_release not found, assuming Ubuntu..."
        return 0
    fi
    
    DISTRO=$(lsb_release -si)
    VERSION=$(lsb_release -sr)
    
    if [[ "$DISTRO" != "Ubuntu" ]]; then
        print_error "This script is designed for Ubuntu systems."
        print_status "Detected: $DISTRO $VERSION"
        exit 1
    fi
    
    print_success "Detected Ubuntu $VERSION"
}

# Function to check if DisplayLink device is connected
check_displaylink_device() {
    print_status "Checking for DisplayLink devices..."
    
    if lsusb | grep -i displaylink > /dev/null; then
        DEVICE=$(lsusb | grep -i displaylink)
        print_success "DisplayLink device detected: $DEVICE"
        return 0
    else
        print_warning "No DisplayLink device detected."
        print_status "Please ensure your DisplayLink dock is connected via USB."
        read -p "Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Exiting..."
            exit 0
        fi
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Update package list
    sudo apt update -qq
    
    # Install required packages
    PACKAGES=(
        "dkms"
        "build-essential"
        "linux-headers-$(uname -r)"
    )
    
    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_status "Installing $package..."
            sudo apt install -y "$package" >> "$LOG_FILE" 2>&1
        else
            print_status "$package is already installed"
        fi
    done
    
    print_success "Dependencies installed successfully"
}

# Function to clean up previous installations
cleanup_previous() {
    print_status "Cleaning up previous installation attempts..."
    
    # Remove old repository files
    sudo rm -f /etc/apt/sources.list.d/synaptics.list
    
    print_success "Cleanup completed"
}

# Function to install DisplayLink using official methods
install_displaylink() {
    print_status "Installing DisplayLink driver..."
    
    # Method 1: Use Ubuntu's official package if available
    print_status "Attempting to install DisplayLink via official channels..."
    
    # Try to install using apt (some Ubuntu versions have this)
    if sudo apt install -y displaylink-driver 2>/dev/null; then
        print_success "DisplayLink driver installed via apt"
        return 0
    fi
    
    # Method 2: Manual installation
    print_status "Downloading DisplayLink driver from official source..."
    
    # Download directly from DisplayLink/Synaptics
    if wget -O /tmp/displaylink-driver.run "https://www.synaptics.com/sites/default/files/exe_files/2024-08/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu5.8-EXE.zip" >> "$LOG_FILE" 2>&1; then
        print_status "Installing DisplayLink driver..."
        chmod +x /tmp/displaylink-driver.run
        sudo /tmp/displaylink-driver.run --noexec --target /tmp/displaylink-extract
        cd /tmp/displaylink-extract
        sudo ./displaylink-installer.sh >> "$LOG_FILE" 2>&1
        print_success "DisplayLink driver installed successfully"
    else
        print_error "Failed to download DisplayLink driver"
        print_status "Please check your internet connection and try again"
        print_status "Alternatively, download manually from: https://www.synaptics.com/products/displaylink-graphics/downloads/ubuntu"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if service exists
    if systemctl list-unit-files | grep -q dlm.service; then
        print_success "DisplayLink service (dlm.service) is installed"
    else
        print_warning "DisplayLink service not found, but installation may still work"
    fi
    
    # Check for kernel modules
    if lsmod | grep -q evdi; then
        print_success "EVDI kernel module is loaded"
    else
        print_status "EVDI kernel module not currently loaded (normal before reboot)"
    fi
}

# Function to provide post-installation instructions
post_install_instructions() {
    print_success "Installation completed successfully!"
    echo
    print_status "=== NEXT STEPS ==="
    echo "1. A system reboot is required to activate the DisplayLink drivers"
    echo "2. After reboot, connect your monitors to the DisplayLink dock"
    echo "3. Your displays should be detected automatically"
    echo
    print_status "=== TROUBLESHOOTING ==="
    echo "If displays don't appear after reboot, try these commands:"
    echo "  xrandr --listmonitors"
    echo "  xrandr --auto"
    echo "  xrandr --setprovideroutputsource 1 0"
    echo
    print_status "=== SUPPORT ==="
    echo "This installer was created by Thugney"
    echo "Repository: https://github.com/Thugney/Displaylink-ubuntu-installer"
    echo
    print_status "=== LOG FILE ==="
    echo "Installation log saved to: $LOG_FILE"
    echo
}

# Function to ask for reboot
ask_reboot() {
    echo
    print_warning "A system reboot is required to complete the installation."
    echo
    while true; do
        read -p "$(echo -e "${YELLOW}Would you like to reboot now? (y/N): ${NC}")" -r
        case $REPLY in
            [Yy]* ) 
                print_status "Rebooting system..."
                sudo reboot
                break
                ;;
            [Nn]* | "" ) 
                print_status "Reboot postponed."
                print_warning "Remember to reboot your system before using DisplayLink devices."
                break
                ;;
            * ) 
                echo "Please answer yes (y) or no (n)."
                ;;
        esac
    done
}

# Main function
main() {
    echo
    echo "=============================================="
    echo "    DisplayLink Auto Installer for Ubuntu    "
    echo "           Created by Thugney               "
    echo "=============================================="
    echo
    
    # Initialize log file
    echo "DisplayLink installation log - $(date)" > "$LOG_FILE"
    echo "Installer version: 1.0.0" >> "$LOG_FILE"
    echo "Repository: https://github.com/Thugney/Displaylink-ubuntu-installer" >> "$LOG_FILE"
    
    # Run checks and installation
    check_root
    check_ubuntu_version
    check_displaylink_device
    cleanup_previous
    install_dependencies
    install_displaylink
    verify_installation
    post_install_instructions
    
    # Cleanup temporary files
    rm -rf /tmp/displaylink-driver.run /tmp/displaylink-extract
    
    # Ask for reboot
    ask_reboot
}

# Handle script interruption
trap 'print_error "Installation interrupted by user"; exit 130' INT

# Run main function
main "$@"