#!/bin/bash

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --gen-sample-log)
            export GEN_SAMPLE_LOG=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--gen-sample-log]"
            echo "  --gen-sample-log  Generate sample logs for easch API called during the load test."
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

print_section "Enter Credentials"

# Create or overwrite .env file
echo "# Stored credentials" >.env

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
    echo "$key=\"$value\"" >>.env
}

# Collect main credentials
collect_input "HYPERSWITCH_HOST_URL" "Hyperswitch host URL" "${CYAN}e.g., http://localhost:8080${RESET}"
collect_input "ADMIN_API_KEY" "Admin API Key"

# Ask if the user wants to track storage
while true; do
    echo -e "\n${YELLOW}Do you wish to provide your Postgres Credentials to track your storage automatically during load test? [y/n]: ${RESET}\c"
    read -r track_storage
    track_storage=$(echo "$track_storage" | tr '[:upper:]' '[:lower:]')
    if [[ "$track_storage" == "y" || "$track_storage" == "n" ]]; then
        break
    else
        echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${RESET}"
    fi
done

if [[ "$track_storage" == "y" || "$track_storage" == "Y" ]]; then
    print_section "Checking for psql Client"

    # Check if psql is installed and has correct version
    if ! command -v psql &>/dev/null; then
        echo -e "${RED}❌ psql is not installed.${RESET}"
        while true; do
            echo -e "${YELLOW}Would you like to continue without storage tracking? [y/n]: ${RESET}\c"
            read -r continue_without_psql
            continue_without_psql=$(echo "$continue_without_psql" | tr '[:upper:]' '[:lower:]')
            if [[ "$continue_without_psql" == "y" || "$continue_without_psql" == "n" ]]; then
                break
            else
                echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${RESET}"
            fi
        done
        if [[ "$continue_without_psql" == "y" ]]; then
            echo "STORAGE_PERMISSION=false" >>.env
            echo -e "${YELLOW}Continuing without storage tracking...${RESET}"
        else
            echo -e "${RED}Please install psql (version >= 13.1) and run this script again.${RESET}"
            exit 1
        fi
    else
        # Check psql version
        version=$(psql --version | awk '{print $3}')
        current_major=${version%%.*}
        current_minor=${version#*.}
        current_minor=${current_minor%%.*}

        if ((current_major < 13)) || { ((current_major == 13)) && ((current_minor < 1)); }; then
            echo -e "${RED}❌ Your psql version is old. Required version >= 13.1${RESET}"
            while true; do
                echo -e "${YELLOW}Would you like to continue without storage tracking? [y/n]: ${RESET}\c"
                read -r continue_without_psql
                continue_without_psql=$(echo "$continue_without_psql" | tr '[:upper:]' '[:lower:]')
                if [[ "$continue_without_psql" == "y" || "$continue_without_psql" == "n" ]]; then
                    break
                else
                    echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${RESET}"
                fi
            done
            if [[ "$continue_without_psql" == "y" ]]; then
                echo "STORAGE_PERMISSION=false" >>.env
                echo -e "${YELLOW}Continuing without storage tracking...${RESET}"
            else
                echo -e "${RED}Please install psql version >= 13.1 and run this script again.${RESET}"
                exit 1
            fi
        else
            echo "STORAGE_PERMISSION=true" >>.env
            echo -e "\n${CYAN}Collecting PostgreSQL credentials...${RESET}"

            collect_input "POSTGRES_USERNAME" "PostgreSQL Username"
            collect_input "POSTGRES_PASSWORD" "PostgreSQL Password"
            collect_input "POSTGRES_DBNAME" "PostgreSQL Database Name"
            collect_input "POSTGRES_HOST" "PostgreSQL Host" "${CYAN}e.g., localhost${RESET}"
            collect_input "POSTGRES_PORT" "PostgreSQL Port"
        fi
    fi
else
    echo "STORAGE_PERMISSION=false" >>.env
fi

# Ask if the user wants to include Grafana Dashboard snapshots
while true; do
    echo -e "\n${YELLOW}Do you wish to include Grafana Dashboard snapshots in your load test report? [y/n]: ${RESET}\c"
    read -r include_grafana
    include_grafana=$(echo "$include_grafana" | tr '[:upper:]' '[:lower:]')
    if [[ "$include_grafana" == "y" || "$include_grafana" == "n" ]]; then
        break
    else
        echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${RESET}"
    fi
done

if [[ "$include_grafana" == "y" || "$include_grafana" == "Y" ]]; then
    echo "GRAFANA_PERMISSION=true" >>.env
    echo -e "\n${CYAN}Collecting Grafana credentials...${RESET}"

    collect_input "GRAFANA_HOST" "Grafana Host" "${CYAN}e.g., http://localhost:3000${RESET}"
    collect_input "GRAFANA_SERVICE_ACCOUNT_TOKEN" "Grafana Service Account Token"
    collect_input "GRAFANA_USERNAME" "Grafana Username"
    collect_input "GRAFANA_PASSWORD" "Grafana Password"
else
    echo "GRAFANA_PERMISSION=false" >>.env
fi

print_section "Finalizing Setup"
echo -e "${GREEN}✔ Credentials stored in .env file securely.${RESET}\n"

# Run Python script and exit if it fails
echo -e "${YELLOW}Running script.py...${RESET}\n"
if ! python3 script.py; then
    echo -e "${RED}❌ script.py failed! Exiting.${RESET}"
    exit 1
fi
