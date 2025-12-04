#!/bin/bash

# AWS CLI Installation Script for Ubuntu with Visual Progress
# This script installs AWS CLI v2 with beautiful visual feedback

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Icons
CHECK="✓"
CROSS="✗"
ARROW="➜"
ROCKET="🚀"
PACKAGE="📦"
WRENCH="🔧"
CLEAN="🧹"
PARTY="🎉"

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           AWS CLI v2 INSTALLER FOR UBUNTU                  ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Print step header
print_step() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# Print success message
print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

# Print info message
print_info() {
    echo -e "${YELLOW}${ARROW} $1${NC}"
}

# Progress bar function
progress_bar() {
    local duration=$1
    local width=50
    local progress=0
    
    while [ $progress -le $width ]; do
        echo -ne "\r${CYAN}["
        for ((i=0; i<$progress; i++)); do echo -ne "█"; done
        for ((i=$progress; i<$width; i++)); do echo -ne "░"; done
        local percent=$((progress * 100 / width))
        echo -ne "] ${percent}%${NC}"
        progress=$((progress + 1))
        sleep $(echo "scale=3; $duration / $width" | bc)
    done
    echo ""
}

# Animated spinner
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${CYAN}%c${NC} ${message}..." "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    printf "\r${GREEN}${CHECK}${NC} ${message}... Done!\n"
}

# Main installation
main() {
    print_banner
    
    echo -e "${ROCKET} ${WHITE}Starting AWS CLI installation...${NC}\n"
    sleep 1
    
    # Step 1: Check if running as root
    print_step "${WRENCH} STEP 1: Checking Permissions"
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi
    print_success "Running with appropriate permissions"
    sleep 1
    
    # Step 2: Update package list
    print_step "${PACKAGE} STEP 2: Updating Package Lists"
    print_info "Updating apt package index..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating packages"
    
    # Step 3: Install dependencies
    print_step "${WRENCH} STEP 3: Installing Dependencies"
    print_info "Installing required packages: unzip, curl..."
    sudo apt-get install -y unzip curl > /dev/null 2>&1 &
    spinner $! "Installing dependencies"
    
    # Step 4: Download AWS CLI
    print_step "${PACKAGE} STEP 4: Downloading AWS CLI v2"
    print_info "Downloading from AWS..."
    
    cd /tmp
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &
    local download_pid=$!
    
    while kill -0 $download_pid 2>/dev/null; do
        if [ -f "awscliv2.zip" ]; then
            local size=$(du -h awscliv2.zip 2>/dev/null | cut -f1)
            printf "\r${CYAN}↓${NC} Downloading... ${YELLOW}${size}${NC}"
        fi
        sleep 0.5
    done
    
    wait $download_pid
    echo ""
    print_success "Download completed!"
    
    # Step 5: Extract archive
    print_step "${PACKAGE} STEP 5: Extracting Files"
    print_info "Extracting AWS CLI archive..."
    unzip -q awscliv2.zip &
    spinner $! "Extracting files"
    
    # Step 6: Install AWS CLI
    print_step "${WRENCH} STEP 6: Installing AWS CLI"
    print_info "Installing to /usr/local/aws-cli..."
    
    # Check if AWS CLI is already installed
    if [ -d "/usr/local/aws-cli" ]; then
        print_info "Existing installation found. Updating..."
        sudo ./aws/install --update > /dev/null 2>&1 &
    else
        sudo ./aws/install > /dev/null 2>&1 &
    fi
    spinner $! "Installing AWS CLI"
    
    # Step 7: Cleanup
    print_step "${CLEAN} STEP 7: Cleaning Up"
    print_info "Removing temporary files..."
    rm -rf awscliv2.zip aws/
    progress_bar 1
    print_success "Cleanup completed!"
    
    # Step 8: Verify installation
    print_step "${ROCKET} STEP 8: Verifying Installation"
    sleep 1
    
    if command -v aws &> /dev/null; then
        local version=$(aws --version 2>&1)
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                            ║${NC}"
        echo -e "${GREEN}║  ${PARTY}  Installation Successful! ${PARTY}                           ║${NC}"
        echo -e "${GREEN}║                                                            ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Installed Version:${NC}"
        echo -e "${CYAN}$version${NC}"
        echo ""
        echo -e "${YELLOW}${ARROW} Next Steps:${NC}"
        echo -e "  1. Configure AWS CLI: ${CYAN}aws configure${NC}"
        echo -e "  2. Test connection: ${CYAN}aws sts get-caller-identity${NC}"
        echo -e "  3. View help: ${CYAN}aws help${NC}"
        echo ""
    else
        print_error "Installation failed. AWS CLI command not found."
        exit 1
    fi
}

# Run main function
main
