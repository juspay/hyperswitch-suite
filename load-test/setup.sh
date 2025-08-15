#!/bin/bash

# Define color codes
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}========================================${RESET}"
    echo -e "${CYAN}$1${RESET}"
    echo -e "${CYAN}========================================${RESET}\n"
}

# Function to check required dependencies
check_dependencies() {
    local missing_deps=()

    # Check Python3
    if ! command -v python3 &>/dev/null; then
        missing_deps+=("python3")
    fi

    # Check pip3
    if ! command -v pip3 &>/dev/null; then
        missing_deps+=("pip3")
    fi

    # If any dependencies are missing, print error and exit
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ Required dependencies are missing:${RESET}"
        for dep in "${missing_deps[@]}"; do
            echo -e "${RED}  - $dep${RESET}"
        done
        echo -e "\n${YELLOW}Please install the missing dependencies before running this script.${RESET}"
        exit 1
    fi
}

# Check for required dependencies
print_section "Checking Dependencies"
check_dependencies
echo -e "${GREEN}✔ Python3 and pip3 are installed.${RESET}"

print_section "Setting Up Virtual Environment"

# Create virtual environment
python3 -m venv test_env
echo -e "${GREEN}✔ Virtual environment 'test_env' created.${RESET}"

# Activate the virtual environment
source "test_env/bin/activate"
echo -e "${GREEN}✔ Virtual environment activated.${RESET}"

# Upgrade pip
pip install --upgrade pip >/dev/null 2>&1
echo -e "${GREEN}✔ Pip upgraded.${RESET}\n"

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Installing dependencies from requirements.txt...${RESET}"
    pip install --requirement requirements.txt | grep --invert-match --extended-regexp "Requirement already satisfied|already installed"
    echo -e "${GREEN}✔ Dependencies installed.${RESET}"
else
    echo -e "${RED}No requirements.txt found. Skipping dependency installation.${RESET}"
fi

# Install Playwright browsers silently
playwright install >/dev/null 2>&1

echo -e "\n${GREEN}✔ Virtual environment 'test_env' is set up and activated.${RESET}"
echo -e "To activate it later, use: ${CYAN}source test_env/bin/activate${RESET}\n"

# Run Python script and exit if it fails
echo -e "\n${YELLOW}Running script.py...${RESET}\n"
if ! python3 script.py; then
    echo -e "${RED}❌ script.py failed! Exiting.${RESET}"
    exit 1
fi
