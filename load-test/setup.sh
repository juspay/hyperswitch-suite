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

# Function to install Python and pip
install_python() {
    echo -e "${YELLOW}Python3 and pip are required. Installing...${RESET}"
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y python3 python3-pip python3-venv
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y python3 python3-pip python3-virtualenv
    else
        echo -e "${RED}Unsupported OS. Please install Python manually.${RESET}"
        exit 1
    fi
}

# Check if Python is installed
if ! command -v python3 &>/dev/null; then
    install_python
fi

# Check if pip is installed
if ! command -v pip3 &>/dev/null; then
    install_python
fi

print_section "Setting Up Virtual Environment"

# Create virtual environment
python3 -m venv test_env
echo -e "${GREEN}✔ Virtual environment 'test_env' created.${RESET}"

# Activate the virtual environment
source "test_env/bin/activate"
echo -e "${GREEN}✔ Virtual environment activated.${RESET}"

# Upgrade pip
pip install --upgrade pip > /dev/null 2>&1
echo -e "${GREEN}✔ Pip upgraded.${RESET}\n"

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Installing dependencies from requirements.txt...${RESET}"
    pip install -r requirements.txt | grep -vE "Requirement already satisfied|already installed"
    echo -e "${GREEN}✔ Dependencies installed.${RESET}"
else
    echo -e "${RED}No requirements.txt found. Skipping dependency installation.${RESET}"
fi

echo -e "\n${GREEN}✔ Virtual environment 'test_env' is set up and activated.${RESET}"
echo -e "To activate it later, use: ${CYAN}source test_env/bin/activate${RESET}\n"

print_section "Enter Credentials"

credentials_keys=("HYPERSWITCH_HOST_URL" "GRAFANA_HOST" "GRAFANA_TOKEN" "GRAFANA_USERNAME" "GRAFANA_PASSWORD")
credentials_prompts=("Hyperswitch host URL" "Grafana Host" "Grafana Service Account Token" "Grafana Username" "Grafana Password")

# Create or overwrite .env file
echo "# Stored credentials" > .env

# Loop through the credentials
for ((i = 0; i < ${#credentials_keys[@]}; i++)); do
    key="${credentials_keys[$i]}"
    prompt="${credentials_prompts[$i]}"

    echo -e "➡ Enter $prompt : \c"
    read value

    # Save credentials to .env file
    echo "$key=\"$value\"" >> .env
done

print_section "Finalizing Setup"

echo -e "${GREEN}✔ Credentials stored in .env file securely.${RESET}\n"

# Run Python script
echo -e "${YELLOW}Running script.py...${RESET}\n"
python3 script.py
