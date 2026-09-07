#!/bin/bash

# Environment configuration (will be set by user selection)
ENVIRONMENT=""

# Base paths for configuration files
CONFIG_BASE_PATH=""
ALBCONTROLLER_APP_FILE=""
ESO_APP_FILE=""
EXTERNALSECRETS_APP_FILE=""
ARGOCD_APP_FILE=""
ARGOAPPS_APP_FILE=""

NAMESPACES_FOR_SECRET_CREATION="argocd atlantis"

# Function to set environment paths based on selected environment
set_environment_paths() {
    local env="$1"
    ENVIRONMENT="$env"
    CONFIG_BASE_PATH="./management-${env}"
    ALBCONTROLLER_APP_FILE="${CONFIG_BASE_PATH}/apps/alb-controller.yaml"
    ESO_APP_FILE="${CONFIG_BASE_PATH}/apps/eso.yaml"
    EXTERNALSECRETS_APP_FILE="${CONFIG_BASE_PATH}/apps/external-secrets.yaml"
    ARGOCD_APP_FILE="${CONFIG_BASE_PATH}/apps/argocd.yaml"
    ARGOAPPS_APP_FILE="${CONFIG_BASE_PATH}/argo-apps.yaml"
}

# Color definitions
WHITE='\033[0;37m'  # white
CYAN='\033[0;36m'   # Sky blue/cyan
GREEN='\033[0;32m'  # Green
GREY='\033[0;90m'   # Grey
YELLOW='\033[1;33m' # Yellow
NC='\033[0m'        # No Color

# Bright colors
COLORS_BRIGHT=(
    '\033[0;33m' # Yellow (Vanilla)
    '\033[0;32m' # Green (Vue)
    '\033[0;36m' # Cyan (React)
    '\033[0;35m' # Purple (Preact)
    '\033[0;95m' # Light Magenta/Pink (Lit)
    '\033[0;31m' # Red/Orange (Svelte)
    '\033[0;34m' # Blue (Solid)
    '\033[0;36m' # Teal (Qwik)
    '\033[0;31m' # Red (Angular)
    '\033[0;35m' # Magenta (Marko)
)

# Dull colors (dim version)
COLORS_DULL=(
    '\033[2;33m'
    '\033[2;32m'
    '\033[2;36m'
    '\033[2;35m'
    '\033[2;95m'
    '\033[2;31m'
    '\033[2;34m'
    '\033[2;36m'
    '\033[2;31m'
    '\033[2;35m'
)

# Function to center text
center_text() {
    local text="$1"
    local width=$(tput cols)
    local padding=$(((width - ${#text}) / 2))
    printf "%*s%s\n" $padding "" "$text"
}

# Hyperswitch ASCII logo
hyperswitch_logo() {
    clear
    tput civis
    # Position cursor for animation
    echo -ne "\n\n\n\n"
    # Save cursor position before dots animation
    tput sc
    # Animation loop
    for i in {1..3}; do
        # Restore cursor position
        tput rc
        # Clear current line
        tput el
        center_text "●"
        sleep 0.3
        # Move cursor up one line to overwrite
        tput cuu1
        tput el
        center_text "● ● ●"
        sleep 0.3
        # Move cursor up to prepare for next iteration
        tput cuu1
    done

    # Final clear of the dots line
    tput el

    # Now display the logo
    echo -e "${CYAN}"
    center_text "██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗██╗    ██╗██╗████████╗ ██████╗██╗  ██╗"
    center_text "██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║    ██║██║╚══██╔══╝██╔════╝██║  ██║"
    center_text "███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████╗██║ █╗ ██║██║   ██║   ██║     ███████║"
    center_text "██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗╚════██║██║███╗██║██║   ██║   ██║     ██╔══██║"
    center_text "██║  ██║   ██║   ██║     ███████╗██║  ██║███████║╚███╔███╔╝██║   ██║   ╚██████╗██║  ██║"
    center_text "╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝"
    echo -e "${NC}"

    # Tagline animation
    echo -ne "\n"
    center_text "Management Cluster bootstrap Script"
    echo -ne "\n\n\n\n"
    # Restore cursor visibility
    tput cnorm
}

# Animated text reveal
reveal_text() {
    local text="$1"
    local color="$2" || $WHITE
    local delay="$3" || "0.02"

    echo -ne "$color"
    for ((i = 0; i < ${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo -e "$NC"
}

# Universal styled input/select function
styled_prompt() {
    local prompt_text="$1"
    local prompt_type="$2" # "input" or "select"
    shift 2
    local -a options=("$@")
    local result=""
    tput cuu 1
    tput cr
    tput el
    if [[ "$prompt_type" == "input" ]]; then
        # Input mode - show diamond and get text input
        echo -e "${GREY}│${NC}"
        echo -e "${CYAN}◆${NC}  \c"
        reveal_text "$prompt_text:" "$WHITE" "0.02"
        echo -e "${CYAN}│${NC}  \c"
        tput sc # Save cursor position
        echo -e "\n${CYAN}└${NC}"
        tput rc # Restore cursor position
        # Custom input handling with backspace support
        local input=""
        local char

        # Show cursor
        tput cnorm

        while IFS= read -r -n1 -s char; do
            if [[ $char == $'\x7f' ]] || [[ $char == $'\x08' ]]; then
                # Backspace key
                if [[ -n "$input" ]]; then
                    input="${input%?}"
                    # Move cursor back, print space, move cursor back again
                    echo -ne "\b \b"
                fi
            elif [[ $char == "" ]]; then
                # Enter key
                echo
                break
            elif [[ $char == $'\x1b' ]]; then
                # Escape sequence (arrow keys, etc.) - skip for now
                read -r -n2 -s
            else
                # Regular character
                input="${input}${char}"
                echo -n "$char"
            fi
        done

        result="$input"
        echo -e "${CYAN}│${NC}"

        # Store result in global variable
        PROMPT_RESULT="$result"

        # Move cursor up to overwrite the input line
        tput cuu 3
        # Move cursor to the start of the line
        tput cr
        # Redraw the prompt with the result
        echo -e "${GREEN}◇${NC}  ${prompt_text}:"
        echo -e "${GREY}│${NC}  ${GREY}${result}${NC}"
        echo -e "${GREY}└${NC}"

    elif [[ "$prompt_type" == "select" ]]; then
        # Select mode - show options and allow selection
        local selected=0
        local num_options=${#options[@]}

        # Initial display
        echo -e "${GREY}│${NC}"
        echo -e "${CYAN}◆${NC}  \c"
        reveal_text "$prompt_text:" "$WHITE" "0.02"

        # Save cursor position after header
        local start_line=$(tput lines)

        # Display options initially
        for i in "${!options[@]}"; do
            # Pick color index: cycle using modulo
            color_index=$((i % ${#COLORS_BRIGHT[@]}))
            if [ $i -eq $selected ]; then
                color="${COLORS_BRIGHT[$color_index]}"
                echo -e "${CYAN}│${NC}  ${GREEN}●${NC} ${color}${options[$i]}${NC}"
            else
                color="${COLORS_DULL[$color_index]}"
                echo -e "${CYAN}│${NC}  ${GREY}○${NC} ${color}${options[$i]}${NC}"
            fi
        done
        echo -e "${CYAN}└${NC}"

        # Hide cursor
        tput civis

        while true; do
            # Read single character
            read -rsn1 key

            # Handle arrow keys
            if [[ $key == $'\x1b' ]]; then
                read -rsn2 key
                case $key in
                '[A') # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((num_options - 1))
                    fi
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    if [ $selected -ge $num_options ]; then
                        selected=0
                    fi
                    ;;
                esac

                # Move cursor up to start of options
                tput cuu $((num_options + 1))

                # Redraw options
                for i in "${!options[@]}"; do
                    color_index=$((i % ${#COLORS_BRIGHT[@]}))
                    if [ $i -eq $selected ]; then
                        color="${COLORS_BRIGHT[$color_index]}"
                        echo -e "${CYAN}│${NC}  ${GREEN}●${NC} ${color}${options[$i]}${NC}"
                    else
                        color="${COLORS_DULL[$color_index]}"
                        echo -e "${CYAN}│${NC}  ${GREY}○${NC} ${color}${options[$i]}${NC}"
                    fi
                done
                echo -e "${CYAN}└${NC}"

            elif [[ $key == "" ]]; then # Enter key
                lines_to_clear=$((${#options[@]} + 1))
                for ((i = 0; i < lines_to_clear; i++)); do
                    tput cuu1 # move cursor up 1 line
                    tput cr   # carriage return (start of line)
                    tput el   # clear to end of line
                done
                break
            fi
        done

        tput cuu 1
        tput cr
        echo -e "${GREEN}◇${NC}  ${prompt_text}:"
        echo -e "${GREY}│${NC}  ${GREY}${options[$selected]}${NC}"
        echo -e "${GREY}└${NC}"

        # Show cursor again
        tput cnorm

        # Store result in global variable
        PROMPT_RESULT="${options[$selected]}"
    fi
}

# AWS Setup Flow
aws_setup() {
    # Check AWS credentials silently
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo -e "${YELLOW}✗ AWS credentials not configured or invalid.${NC}"
        return
    fi

    # Get AWS Region
    styled_prompt "AWS Region" "input"
    aws_region="$PROMPT_RESULT"

    # Get list of EKS clusters
    clusters=$(aws eks list-clusters --region "$aws_region" --output text --query 'clusters[]' 2>/dev/null)

    if [[ -z "$clusters" ]]; then
        echo -e "${YELLOW}No EKS clusters found in region $aws_region.${NC}"
        return
    fi

    # Convert clusters to array
    IFS=$'\t' read -r -a cluster_array <<< "$clusters"

    # Let user select cluster
    styled_prompt "Select EKS Cluster" "select" "${cluster_array[@]}"
    selected_cluster="$PROMPT_RESULT"

    # Update kubeconfig
    kubeconfig_output=$(aws eks update-kubeconfig --region "$aws_region" --name "$selected_cluster" 2>&1)
    kubeconfig_exit=$?

    if [[ $kubeconfig_exit -ne 0 ]]; then
        echo -e "${YELLOW}Failed to update kubeconfig.${NC}"
        return
    fi

    helm_installation
}

# Check and add helm repo if needed
check_helm_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local chart_name="$3"
    local chart_version="$4"

    if ! helm repo list | grep -q "^${repo_name}"; then
        helm repo add "${repo_name}" "${repo_url}" > /dev/null
    fi

    if ! helm search repo "${repo_name}/${chart_name}" --version "${chart_version}" | grep -q "${chart_version}"; then
        helm repo update "${repo_name}" > /dev/null
    fi
}

# Global variable for helm command
HELM_CMD="upgrade --install"

# Spinner characters
SPINNER_CHARS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# Function to run a command with a spinner
run_with_spinner() {
    local message="$1"
    shift
    local cmd=("$@")
    local pid
    local spin_idx=0
    local tmp_output=$(mktemp)

    # Move cursor up to the "└" line and clear it
    tput cuu1
    tput cr
    tput el

    # Hide cursor
    tput civis

    # Start the command in background, capture output
    "${cmd[@]}" > "$tmp_output" 2>&1 &
    pid=$!

    # Show spinner while command is running (inline)
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${CYAN}└${NC}  ${CYAN}${SPINNER_CHARS[$spin_idx]}${NC} ${message}\033[K"
        spin_idx=$(( (spin_idx + 1) % ${#SPINNER_CHARS[@]} ))
        sleep 0.1
    done

    # Wait for command to finish and get exit code
    wait $pid
    local exit_code=$?

    # Clear the spinner, show completion with checkmark, change └ to grey │
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\r${GREY}│${NC}  ${GREEN}✓${NC} ${message}\033[K"
        echo -e "${GREY}└${NC}"
    else
        echo -e "\r${GREY}│${NC}  ${YELLOW}✗${NC} ${message}\033[K"
        echo -e "${GREY}└${NC}"
    fi

    # Show cursor
    tput cnorm

    # Show output only on error
    if [[ $exit_code -ne 0 ]]; then
        cat "$tmp_output"
    fi

    rm -f "$tmp_output"
    return $exit_code
}

# Extract helm values from ArgoCD app file using yq
get_app_values() {
    local app_file="$1"

    local app_key
    app_key=$(yq e '.applications | keys | .[0]' "$app_file")

    local app_path=".applications.[\"$app_key\"]"

    local release_name
    release_name=$(yq e "${app_path}.sources[0].helm.releaseName // \"$app_key\"" "$app_file")

    local chart_version
    chart_version=$(yq e "${app_path}.sources[0].targetRevision" "$app_file")

    local namespace
    namespace=$(yq e "${app_path}.destination.namespace" "$app_file")

    # Build set args from parameters
    local set_args=()
    local param_count
    param_count=$(yq e "${app_path}.sources[0].helm.parameters | length" "$app_file")
    if [[ "$param_count" != "null" && "$param_count" -gt 0 ]]; then
        for ((i=0; i<param_count; i++)); do
            local param_name
            param_name=$(yq e "${app_path}.sources[0].helm.parameters[$i].name" "$app_file")
            local param_value
            param_value=$(yq e "${app_path}.sources[0].helm.parameters[$i].value" "$app_file")
            if [[ -n "$param_name" && "$param_name" != "null" ]]; then
                set_args+=("--set" "${param_name}=${param_value}")
            fi
        done
    fi

    # Build value files args, stripping $values/ prefix
    local value_files=()
    local vf_count
    vf_count=$(yq e "${app_path}.sources[0].helm.valueFiles | length" "$app_file")
    if [[ "$vf_count" != "null" && "$vf_count" -gt 0 ]]; then
        for ((i=0; i<vf_count; i++)); do
            local vf_path
            vf_path=$(yq e "${app_path}.sources[0].helm.valueFiles[$i]" "$app_file")
            if [[ -n "$vf_path" && "$vf_path" != "null" ]]; then
                # Strip $values/ prefix
                vf_path="${vf_path#\$values/}"
                value_files+=("-f" "${vf_path}")
            fi
        done
    fi

    # Output using newlines as delimiters to handle spaces in args
    printf '%s\n' "$release_name" "$chart_version" "$namespace" "${set_args[*]}" "${value_files[*]}"
}

# Helm Installation Flow
helm_installation() {
    # Ask about helm tfstate plugin
    styled_prompt "Use helm tfstate plugin" "select" "no" "yes"
    use_tfstate="$PROMPT_RESULT"

    if [[ "$use_tfstate" == "yes" ]]; then
        if ! helm plugin list | grep -q "tfstate"; then
            echo -e "${YELLOW}✗ helm tfstate plugin not installed.${NC}"
        else
            HELM_CMD="tfstate upgrade --install"
        fi
    fi

    # Install ALB Controller
    styled_prompt "Proceed with ALB Controller installation" "select" "yes" "skip" "exit"
    install_alb="$PROMPT_RESULT"
    if [[ "$install_alb" == "exit" ]]; then
        exit 0
    elif [[ "$install_alb" == "yes" ]]; then
        # Read values from get_app_values into variables
        {
            read -r alb_release
            read -r alb_version
            read -r alb_namespace
            read -r alb_set_args_str
            read -r alb_value_files_str
        } < <(get_app_values "$ALBCONTROLLER_APP_FILE")
        # Convert space-separated strings to arrays
        read -r -a alb_set_args <<< "$alb_set_args_str"
        read -r -a alb_value_files <<< "$alb_value_files_str"
        check_helm_repo "eks" "https://aws.github.io/eks-charts" "aws-load-balancer-controller" "$alb_version"
        if ! run_with_spinner "Installing ALB Controller..." helm $HELM_CMD "$alb_release" eks/aws-load-balancer-controller \
            --version "$alb_version" \
            --namespace "$alb_namespace" \
            --create-namespace \
            --wait \
            "${alb_set_args[@]}" \
            "${alb_value_files[@]}"; then
            return
        fi
    fi

    # Install External Secrets Operator
    styled_prompt "Proceed with ESO installation" "select" "yes" "skip" "exit"
    install_eso="$PROMPT_RESULT"
    if [[ "$install_eso" == "exit" ]]; then
        exit 0
    elif [[ "$install_eso" == "yes" ]]; then
        {
            read -r eso_release
            read -r eso_version
            read -r eso_namespace
            read -r eso_set_args_str
            read -r eso_value_files_str
        } < <(get_app_values "$ESO_APP_FILE")
        read -r -a eso_set_args <<< "$eso_set_args_str"
        read -r -a eso_value_files <<< "$eso_value_files_str"
        check_helm_repo "external-secrets" "https://charts.external-secrets.io" "external-secrets" "$eso_version"
        if ! run_with_spinner "Installing External Secrets Operator..." helm $HELM_CMD "$eso_release" external-secrets/external-secrets \
            --version "$eso_version" \
            --namespace "$eso_namespace" \
            --create-namespace \
            --wait \
            "${eso_set_args[@]}" \
            "${eso_value_files[@]}"; then
            return
        fi
    fi

    # Install External Secrets (local chart, no version)
    styled_prompt "Proceed with External Secrets installation" "select" "yes" "skip" "exit"
    install_es="$PROMPT_RESULT"
    if [[ "$install_es" == "exit" ]]; then
        exit 0
    elif [[ "$install_es" == "yes" ]]; then
        {
            read -r es_release
            read -r _
            read -r es_namespace
            read -r es_set_args_str
            read -r es_value_files_str
        } < <(get_app_values "$EXTERNALSECRETS_APP_FILE")
        read -r -a es_set_args <<< "$es_set_args_str"
        read -r -a es_value_files <<< "$es_value_files_str"

        # Create namespaces from the list
        run_with_spinner "Creating namespaces..." bash -c "for ns in $NAMESPACES_FOR_SECRET_CREATION; do kubectl create namespace \"\$ns\" --dry-run=client -o yaml 2>/dev/null | kubectl apply -f - > /dev/null; done"

        if ! run_with_spinner "Installing External Secrets..." helm $HELM_CMD "$es_release" ./helm-charts/charts/external-secrets \
            --namespace "$es_namespace" \
            --create-namespace \
            --wait \
            "${es_set_args[@]}" \
            "${es_value_files[@]}"; then
            return
        fi
    fi

    # Install ArgoCD
    styled_prompt "Proceed with ArgoCD installation" "select" "yes" "skip" "exit"
    install_argocd="$PROMPT_RESULT"
    if [[ "$install_argocd" == "exit" ]]; then
        exit 0
    elif [[ "$install_argocd" == "yes" ]]; then
        {
            read -r argocd_release
            read -r argocd_version
            read -r argocd_namespace
            read -r argocd_set_args_str
            read -r argocd_value_files_str
        } < <(get_app_values "$ARGOCD_APP_FILE")
        read -r -a argocd_set_args <<< "$argocd_set_args_str"
        read -r -a argocd_value_files <<< "$argocd_value_files_str"
        check_helm_repo "argo" "https://argoproj.github.io/argo-helm" "argo-cd" "$argocd_version"
        if ! run_with_spinner "Installing ArgoCD..." helm $HELM_CMD "$argocd_release" argo/argo-cd \
            --version "$argocd_version" \
            --namespace "$argocd_namespace" \
            --create-namespace \
            --wait \
            "${argocd_set_args[@]}" \
            "${argocd_value_files[@]}"; then
            return
        fi
    fi

    # Install ArgoCD Apps
    styled_prompt "Proceed with ArgoCD Apps installation" "select" "yes" "skip" "exit"
    install_argocd_apps="$PROMPT_RESULT"
    if [[ "$install_argocd_apps" == "exit" ]]; then
        exit 0
    elif [[ "$install_argocd_apps" == "yes" ]]; then
        {
            read -r argoapps_release
            read -r argoapps_version
            read -r argoapps_namespace
            read -r argoapps_set_args_str
            read -r argoapps_value_files_str
        } < <(get_app_values "$ARGOAPPS_APP_FILE")
        read -r -a argoapps_set_args <<< "$argoapps_set_args_str"
        read -r -a argoapps_value_files <<< "$argoapps_value_files_str"
        check_helm_repo "argo" "https://argoproj.github.io/argo-helm" "argocd-apps" "$argoapps_version"
        if ! run_with_spinner "Installing ArgoCD Apps..." helm $HELM_CMD "$argoapps_release" argo/argocd-apps \
            --version "$argoapps_version" \
            --namespace "$argoapps_namespace" \
            --create-namespace \
            --wait \
            "${argoapps_set_args[@]}" \
            "${argoapps_value_files[@]}"; then
            return
        fi
    fi
}

# Example usage
main() {
    hyperswitch_logo

    # Choose Environment (local, sandbox, or prod)
    styled_prompt "Select Environment" "select" "local" "sandbox" "prod"
    environment="$PROMPT_RESULT"

    if [[ "$environment" == "local" ]]; then
        echo -e "${YELLOW}Local setup is not yet implemented.${NC}"
        exit 0
    elif [[ "$environment" == "sandbox" ]] || [[ "$environment" == "prod" ]]; then
        set_environment_paths "$environment"
        aws_setup
    else
        echo -e "${RED}Invalid environment selected.${NC}"
    fi
}

# Run the demo
main
