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

# Install Playwright browsers silently
playwright install > /dev/null 2>&1

echo -e "\n${GREEN}✔ Virtual environment 'test_env' is set up and activated.${RESET}"
echo -e "To activate it later, use: ${CYAN}source test_env/bin/activate${RESET}\n"

print_section "Enter Credentials"

credentials_keys=(
    "HYPERSWITCH_HOST_URL|${CYAN}e.g., http://localhost:8080${RESET}"
    "GRAFANA_HOST|${CYAN}e.g., http://localhost:3000${RESET}"
    "GRAFANA_TOKEN|"
    "GRAFANA_USERNAME|"
    "GRAFANA_PASSWORD|"
)
credentials_prompts=("Hyperswitch host URL" "Grafana Host" "Grafana Service Account Token" "Grafana Username" "Grafana Password")

# Create or overwrite .env file
echo "# Stored credentials" > .env

# Function to collect input with optional example
collect_input() {
    local key="$1"
    local prompt="$2"
    local example="$3"

    if [[ -n "$example" ]]; then
        echo -e "➡ Enter $prompt $example: \c"
    else
        echo -e "➡ Enter $prompt: \c"
    fi
    
    read -r value
    echo "$key=\"$value\"" >> .env
}

# Collect main credentials
for ((i = 0; i < ${#credentials_keys[@]}; i++)); do
    IFS="|" read -r key example <<< "${credentials_keys[$i]}"
    collect_input "$key" "${credentials_prompts[$i]}" "$example"
done

# Ask if the user wants to track storage
echo -e "\n${YELLOW}Do you wish to provide your Postgres Credentials to track your storage automatically during load test? [y/n]: ${RESET}\c"
read -r track_storage

if [[ "$track_storage" == "y" || "$track_storage" == "Y" ]]; then

    print_section "Checking for psql Client"

    # Function to compare psql version
    check_psql_version() {
        local min_major=13
        local min_minor=1

        local version
        version=$(psql --version | awk '{print $3}')
        local current_major=${version%%.*}
        local current_minor=${version#*.}
        current_minor=${current_minor%%.*}

        if (( current_major > min_major )) || { (( current_major == min_major )) && (( current_minor >= min_minor )); }; then
            return 0
        else
            return 1
        fi
    }

    # Check if psql is installed
    if ! command -v psql &>/dev/null; then
        echo -e "${RED}❌ psql is not installed.${RESET}"
        echo -e "${YELLOW}Would you like to install the PostgreSQL client now? [y/n]: ${RESET}\c"
        read -r install_psql
        if [[ "$install_psql" == "y" || "$install_psql" == "Y" ]]; then
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt update && sudo apt install -y postgresql-client
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install postgresql
            else
                echo -e "${RED}Unsupported OS. Please install psql manually.${RESET}"
                echo "STORAGE_PERMISSION=false" >> .env
                skip_storage=true
            fi
        else
            echo -e "${YELLOW}Skipping psql installation. Storage tracking disabled.${RESET}"
            echo "STORAGE_PERMISSION=false" >> .env
            skip_storage=true
        fi
    fi

    # Only check version if psql is installed
    if command -v psql &>/dev/null && ! check_psql_version; then
        echo -e "${RED}❌ Your psql version is old. Required version >= 13.1${RESET}"
        echo -e "${YELLOW}Would you like to update it? [y/n]: ${RESET}\c"
        read -r update_psql
        if [[ "$update_psql" == "y" || "$update_psql" == "Y" ]]; then
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt update && sudo apt install -y postgresql-client
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew upgrade postgresql
            else
                echo -e "${RED}Unsupported OS. Please update psql manually.${RESET}"
                echo "STORAGE_PERMISSION=false" >> .env
                skip_storage=true
            fi
        else
            echo -e "${YELLOW}Skipping psql update. Storage tracking disabled.${RESET}"
            echo "STORAGE_PERMISSION=false" >> .env
            skip_storage=true
        fi
    fi

    # If no skip_storage flag is set, continue with credential collection
    if [[ "$skip_storage" != "true" ]]; then
        echo "STORAGE_PERMISSION=true" >> .env
        echo -e "\n${CYAN}Collecting PostgreSQL credentials...${RESET}"

        collect_input "POSTGRES_USERNAME" "PostgreSQL Username"
        collect_input "POSTGRES_PASSWORD" "PostgreSQL Password"
        collect_input "POSTGRES_DBNAME" "PostgreSQL Database Name"
        collect_input "POSTGRES_HOST" "PostgreSQL Host" "${CYAN}e.g., localhost${RESET}"
        collect_input "POSTGRES_PORT" "PostgreSQL Port"
    fi

else
    echo "STORAGE_PERMISSION=false" >> .env
fi

print_section "Finalizing Setup"
echo -e "${GREEN}✔ Credentials stored in .env file securely.${RESET}\n"

# Run Python script and exit if it fails
echo -e "${YELLOW}Running script.py...${RESET}\n"
if ! python3 script.py; then
    echo -e "${RED}❌ script.py failed! Exiting.${RESET}"
    exit 1
fi
