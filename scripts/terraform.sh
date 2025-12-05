#!/bin/bash
# Terraform Installation Script for Ubuntu
# This script installs the latest version of Terraform from HashiCorp

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
TERRAFORM="🏗️"
PACKAGE="📦"
KEY="🔑"
WRENCH="🔧"
ROCKET="🚀"
PARTY="🎉"
DOWNLOAD="⬇️"
CLOUD="☁️"

# Print banner
print_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║      ${TERRAFORM}  TERRAFORM INSTALLER FOR UBUNTU  ${TERRAFORM}           ║"
    echo "║                                                            ║"
    echo "║              Infrastructure as Code Tool                   ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Print step header
print_step() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}\n"
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

# Progress bar function
progress_bar() {
    local duration=$1
    local width=50
    local progress=0
    
    while [ $progress -le $width ]; do
        echo -ne "\r${PURPLE}["
        for ((i=0; i<$progress; i++)); do echo -ne "█"; done
        for ((i=$progress; i<$width; i++)); do echo -ne "░"; done
        local percent=$((progress * 100 / width))
        echo -ne "] ${percent}%${NC}"
        progress=$((progress + 1))
        sleep $(echo "scale=3; $duration / $width" | bc 2>/dev/null || echo "0.02")
    done
    echo ""
}

# Animated download progress
download_progress() {
    local message=$1
    local chars="⣾⣽⣻⢿⡿⣟⣯⣷"
    local i=0
    
    while true; do
        printf "\r${CYAN}${chars:$i:1}${NC} ${message}..."
        i=$(( (i + 1) % ${#chars} ))
        sleep 0.1
    done
}

# Main installation
main() {
    print_banner
    
    echo -e "${TERRAFORM} ${WHITE}Starting Terraform installation...${NC}\n"
    sleep 1
    
    # Step 1: Update package index
    print_step "${PACKAGE} STEP 1: Updating Package Index"
    print_info "Updating apt package lists..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating package index"
    
    # Step 2: Install required dependencies
    print_step "${WRENCH} STEP 2: Installing Dependencies"
    print_info "Installing wget, curl, unzip, and gnupg..."
    sudo apt-get install -y wget curl unzip gnupg software-properties-common > /dev/null 2>&1 &
    spinner $! "Installing dependencies"
    
    # Step 3: Create directory for HashiCorp GPG key
    print_step "${KEY} STEP 3: Preparing HashiCorp GPG Key Directory"
    print_info "Creating secure keyring directory..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    print_success "Directory ready: /etc/apt/keyrings"
    sleep 0.5
    
    # Step 4: Download and add HashiCorp GPG key
    print_step "${KEY} STEP 4: Installing HashiCorp GPG Key"
    print_info "Downloading HashiCorp official GPG key..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null &
    spinner $! "Installing GPG key"
    
    # Step 5: Verify the GPG key fingerprint
    print_step "${KEY} STEP 5: Verifying GPG Key Fingerprint"
    print_info "Checking GPG key authenticity..."
    local fingerprint=$(gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint 2>/dev/null)
    progress_bar 0.5
    print_success "GPG key verified"
    
    # Step 6: Add HashiCorp repository
    print_step "${PACKAGE} STEP 6: Adding HashiCorp Repository"
    print_info "Configuring HashiCorp APT repository..."
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    print_success "HashiCorp repository added"
    sleep 0.5
    
    # Step 7: Update package index with new repository
    print_step "${PACKAGE} STEP 7: Updating Package Index"
    print_info "Refreshing package lists with HashiCorp repository..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating package index"
    
    # Step 8: Install Terraform
    print_step "${TERRAFORM} STEP 8: Installing Terraform"
    print_info "Installing Terraform binary..."
    echo -e "${CYAN}Downloading and installing Terraform...${NC}\n"
    sudo apt-get install -y terraform > /dev/null 2>&1 &
    spinner $! "Installing Terraform"
    print_success "Terraform installed successfully"
    
    # Step 9: Enable Terraform autocompletion
    print_step "${WRENCH} STEP 9: Configuring Terraform Autocompletion"
    print_info "Setting up bash autocompletion..."
    
    # Install autocompletion
    terraform -install-autocomplete 2>/dev/null || true
    progress_bar 0.5
    print_success "Autocompletion configured"
    
    # Step 10: Verify installation
    print_step "${ROCKET} STEP 10: Verifying Installation"
    sleep 1
    
    if command -v terraform &> /dev/null; then
        local terraform_version=$(terraform version | head -n1)
        
        echo ""
        echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                                                            ║${NC}"
        echo -e "${PURPLE}║  ${PARTY}  Terraform Installation Successful! ${PARTY}                ║${NC}"
        echo -e "${PURPLE}║                                                            ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Installed Version:${NC}"
        echo -e "${CYAN}  ${TERRAFORM} ${terraform_version}${NC}"
        echo ""
        echo -e "${YELLOW}${ARROW} Quick Start Guide:${NC}"
        echo ""
        echo -e "${WHITE}1. Initialize a new Terraform project:${NC}"
        echo -e "   ${CYAN}terraform init${NC}"
        echo ""
        echo -e "${WHITE}2. Validate configuration:${NC}"
        echo -e "   ${CYAN}terraform validate${NC}"
        echo ""
        echo -e "${WHITE}3. Plan infrastructure changes:${NC}"
        echo -e "   ${CYAN}terraform plan${NC}"
        echo ""
        echo -e "${WHITE}4. Apply infrastructure changes:${NC}"
        echo -e "   ${CYAN}terraform apply${NC}"
        echo ""
        echo -e "${WHITE}5. Destroy infrastructure:${NC}"
        echo -e "   ${CYAN}terraform destroy${NC}"
        echo ""
        echo -e "${PURPLE}${ARROW} Essential Commands:${NC}"
        echo -e "  • Format code: ${CYAN}terraform fmt${NC}"
        echo -e "  • Show state: ${CYAN}terraform show${NC}"
        echo -e "  • List providers: ${CYAN}terraform providers${NC}"
        echo -e "  • Show output: ${CYAN}terraform output${NC}"
        echo -e "  • Workspace list: ${CYAN}terraform workspace list${NC}"
        echo ""
        echo -e "${PURPLE}${ARROW} Create your first Terraform file:${NC}"
        echo -e "  ${CYAN}cat > main.tf << 'EOF'"
        echo -e "  terraform {"
        echo -e "    required_version = \">= 1.0\""
        echo -e "  }"
        echo -e "  "
        echo -e "  resource \"null_resource\" \"example\" {"
        echo -e "    provisioner \"local-exec\" {"
        echo -e "      command = \"echo Hello, Terraform!\""
        echo -e "    }"
        echo -e "  }"
        echo -e "  EOF${NC}"
        echo ""
        echo -e "${GREEN}${ARROW} Then run: ${CYAN}terraform init && terraform apply${NC}"
        echo ""
        echo -e "${PURPLE}Documentation: ${CYAN}https://www.terraform.io/docs${NC}"
        echo -e "${PURPLE}Registry: ${CYAN}https://registry.terraform.io${NC}"
        echo ""
    else
        print_error "Installation failed. Terraform command not found."
        exit 1
    fi
}

# Run main function
main
