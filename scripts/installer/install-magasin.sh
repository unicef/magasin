#!/bin/bash

# This script checks and installs kubectl, helm, and Homebrew (if needed) on your system.
# It supports automatic installation with the `-y` flag and provides
# detailed user prompts for confirmation. Additionally, it verifies
# the functionality of all tools once installed.



# Magasin base url
BASE_URL=http://unicef.github.io/magasin

VALUES_FOLDER='./'

MAGASIN_HELM_REPO=$BASE_URL

# Link to documentation on how to install magasin manually
MANUAL_INSTALL_LINK=$BASE_URL/install.html#manual-installation

# Skip prompting the user?
AUTO_INSTALL=false

# Only check if there is missing stuff
ONLY_CHECK=false

# Debug mode
DEBUG=false

# Default REALM
REALM_ARG='magasin' # default
REALM_PREFIX='magasin'
REALM_POSTFIX=''

# Get PLATFORM
PLATFORM=$(uname)
LINUX="Linux"
MACOS="Darwin"

# Function to display messages in red
echo_debug() {
  if [ "$DEBUG" = true ]; then
    printf "\033[38;5;208m%s\033[0m\n" "$@"
  fi
}

# Function to display failure to comply with a condition.
# Prepends and x. 
echo_fail() {
    printf "\033[31m \xE2\x9C\x97 %s\033[0m\n" "$@" # \e[31m sets the color to red, \e[0m resets the color
}


# Function to display error messages in red. Prepends ERROR
echo_error() {
    printf " \033[31mERROR: %s\033[0m\n" "$@"
}

# Exit displaying how to debug
exit_error() {
  local code=$1
  echo_error "$code" 
  echo_error "You may get more information about the issue by running the script including the debug option (-d):"
  echo_error "       $script_name -d "
  echo ""
  exit $code
}

# Function to display messages in green
echo_success() {
  printf "\033[32m \xE2\x9C\x93 %s\033[0m\n" "$@"
}

# Information message in blue
echo_info() {
  printf "\033[34m i %s\033[0m\n" "$@"
}

function usage {
  echo "Usage: $1 [-y] [-c] [-r realm_prefix-realm_postfix (magasin)] [-f values_folder (./)] [-d] [-h]"
  echo ""
  echo "This script checks dependencies and installs magasin components"
  echo "Each component is installed within its own namespace."  
  echo ""
  echo "Options:"
  echo "  -y  Skip prompting questions during installation"
  echo "  -c  Only check if all pre-requisites are installed in the local machine."
  echo "  -r  Realm prefix and suffix (default: magasin). Prefix and suffix are separated by '-'." 
  echo "        If more than one '-', the last one will be used as separator." 
  echo "        The realm 'magasin-new-dev' will set 'magasin-new' as prefix and 'dev' as suffix."
  echo "  -f  Folder with custom values.yaml files (default: ./)."
  echo "        Files within the folder shall have the same name as the component. Example:"  
  echo "        drill.yaml, dagster.yaml, superset.yaml, daskhub.yaml"
  echo "  -u  URL/path to the magasin's helm repository (default: https://unicef.github.io/magasin/)"
  echo "      "
  echo "  -d  Enable debug mode (displays all commands run)."
  echo "  -h  Display this help message and exit."
  echo " "
  echo "Examples:"
  echo "   - Only check if all requirements are installed"
  echo "       $1 -c "
  echo "   - Setup the realm 'test'. Will use test-<component> as namespaces"
  echo "       $1 -r test"
  echo "   - Enable debug mode, skip being promted, and setup the realm 'magasin-dev'" 
  echo "     (which results in magasin-<component>-dev as namespaces)"
  echo "       $1 -d -y -r magasin-dev"
  exit 0
}

script_name=$(basename "$0")

while getopts ":f:u:r:ychd" opt; do
  case $opt in
    y)
      AUTO_INSTALL=true
      ;;
    c)
      ONLY_CHECK=true
      ;;
    d)
      DEBUG=true
      ;;
    u) 
      MAGASIN_HELM_REPO=$OPTARG
      ;;
    f)
      # Check if the folder exists.
      if [ -d $OPTARG ]; then
          echo_debug "Values folder exists $OPTARG" 
          VALUES_FOLDER=$OPTARG
          # Check if hte folder name ends with 
          if [[ "$VALUES_FOLDER" != */ ]]; then
            echo_debug "Adding slash to values folder $VALUES_FOLDER" 
            VALUES_FOLDER="$VALUES_FOLDER/"
          fi
          echo_info "Folder with value files exists ($VALUES_FOLDER)."
      else
        echo_error "Folder $OPTARG does not exist."
        exit 101
      fi
      
      ;;
    r)
      argument=$OPTARG
      # Extracting prefix and postfix
      last_dash=$(echo "$argument" | grep -o '[^-]*$')
      if [[ "$last_dash" == "$argument" ]]; then
        REALM_PREFIX=$argument
        REALM_POSTFIX=""
      else
        REALM_PREFIX=${argument%-$last_dash}
        REALM_POSTFIX=$last_dash
      fi
      REALM_ARG=$argument
      echo_info "Magasin realm set:"
      echo_info "   Realm: $REALM_ARG"
      echo_info "   Realm prefix '$REALM_PREFIX'"
      echo_info "   Realm suffix '$REALM_SUFFIX'"

      ;;
    h)
      usage $script_name
      ;;
    \?)
      echo_error "Invalid option: -$OPTARG"
      echo ""
      usage $script_name
      exit 102
      ;;
    :)
      echo_error "Option -$OPTARG requires an argument." >&2
      exit 103
      ;;
  esac
done

# This is addded in helm command line.
HELM_DEBUG_FLAG=''
# If debug display all commands
if [ "$DEBUG" = true ]; then
  echo_info Setting DEBUG mode ON
  # This will enable debug in helm commands. It is added in all helm command calls
  HELM_DEBUG_FLAG=" --debug"
  set -x
fi

# Display 
echo "-----------"
echo_info "BASE_URL: $BASE_URL"
echo_info "MAGASIN_HELM_REPO: $MAGASIN_HELM_REPO"
echo_info "MANUAL_INSTALL_LINK: $MANUAL_INSTALL_LINK"
echo_info "REALM_ARG: $REALM_ARG"
echo_info "REALM_PREFIX: $REALM_PREFIX"
echo_info "REALM_POSTFIX: $REALM_POSTFIX"
echo_info "AUTO_INSTALL: $AUTO_INSTALL"
echo_info "ONLY_CHECK: $ONLY_CHECK"
echo_info "PLATFORM: $PLATFORM"
echo_info "PATH: $PATH"
echo_info "HELM_DEBUG_FLAG: $HELM_DEBUG_FLAG"
echo "-----------"
# Initialize report variables
declare -A install_status

# if a command does not exist this variable is set to true
command_missing=false

# Checks if a command exists. Returns "installed" and "not installed"
# if the command does not exist sets $command_missing to true
function command_exists {
  local command="$1"
  if ! command -v "$command" &> /dev/null; then
    command_missing=true
    echo_fail "$command not installed"
    install_status["$command"]="not installed"
    return 1
  fi
  command_path="$(command -v "$command")"
  echo_success "$command installed ($command_path)"
  install_status["$command"]="installed"
  return 0
}

# Checks if all the required commands to perform the installation are in linux
function check_linux_requirements_status {
  echo_info "** magasin installer for a GNU/Linux system (Linux)"
  command_exists "kubectl"
  command_exists "helm" 
  # only check if any of the previous does not exist
  if [[ "$command_missing" == true ]]; then 
    command_exists "apt-get"  # debian like package installer
  fi
}

# Checks if all the required commands are available for MacOS
function check_macos_requirements_status {
  echo_info "magasin installer for a MacOS system (Darwin)"
  command_exists "kubectl" 
  command_exists "helm" 
  command_exists "pip3"

  if [[ "$command_missing" == true ]]; then
    command_exists "brew" 
  fi
}


# Check based on system
echo ""
if [[ $PLATFORM == $LINUX ]]; then
  check_linux_requirements_status
  
  # Only debian / apt-get systems supported
  
  if [ "${install_status["apt-get"]}" = "not installed" ]; then
    echo ""
    echo_error "apt-get is not installed. Are you in a Debian like system?"
    echo_info "This installation script only works on Debian GNU/Linux like systems (f.i. Debian, Ubuntu, raspbian, Kali...)."
    echo_info "Please read the "Manual Installation" section in:" 
    echo ""
    echo_info "      $MANUAL_INSTALL_LINK"
    echo ""
    exit 1
  fi

elif [[ $PLATFORM == $MACOS ]]; then
  check_macos_requirements_status
else
  echo ""
  echo_error Platform = $PLATFORM
  echo_error "This system is not supported by this installation script."
  echo_info " Please visit $MANUAL_INSTALL_LINK"
  echo ""
  exit 1
fi


echo_debug "Is there any command missing?"
if [[ "$command_missing" == true ]]; then
  echo ""
  echo_fail "There are missing dependencies."
else
  echo ""
  echo_success "All dependencies are installed."
fi

# If -c option is set, then end.
echo_debug "Only check? $ONLY_CHECK"
if [[ "$ONLY_CHECK" == true ]]; then
  echo_debug "ONLY_CHECK=true"
  exit 0
fi

#
# Install missing pre-requisites
# 
# Is there a command missing?

echo_debug "Is there any dependency missing missing? $command_missing" 
if [[ "$command_missing" == true ]]; then
  # Perform installation based on report
  if [[ $PLATFORM == $LINUX ]]; then
    echo_debug "Install missing commands in $LINUX"
    if [[ "$AUTO_INSTALL" == false ]]; then
      # If not auto install Prompt for installation if any tool is missing and -y flag is not provided
      echo ""
      read -r -p "Do you want to install the missing tools (y/N)?" response
      if [[ ! $response =~ ^[Yy]$ ]]; then
        echo_fail "Installation aborted."
        echo_info "For more information on how install manually: $MANUAL_INSTALL_LINK"
        exit 0
      fi # response
    fi # auto_install
    echo_info "Installing pre-requisites for GNU/Linux.."
    if [ "${install_status["kubectl"]}" == "not installed" ]; then
      # https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
      sudo apt-get update   
      # apt-transport-https may be a dummy package; if so, you can skip that package    
      sudo apt-get install -y apt-transport-https ca-certificates curl
      # Note: In releases older than Debian 12 and Ubuntu 22.04, /etc/apt/keyrings does not exist by default, and can be created using sudo mkdir -m 755 /etc/apt/keyrings
      sudo mkdir -m 755 /etc/apt/keyrings
      curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      # This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
      sudo apt-get update
      sudo apt-get install -y kubectl
    fi

    if [ "${install_status["helm"]}" == "not installed" ]; then
      echo_info "Installing helm..."
      curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
      sudo apt-get install apt-transport-https --yes
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
      sudo apt-get update
      sudo apt-get install helm
    fi
    
    if [ "${install_status["pi"]}" == "not installed" ]; then
        sudo apt-get install python3 python3-pip --yes
    fi

  elif [[ $PLATFORM == $MACOS ]]; then
    if [[ "$AUTO_INSTALL" == false ]]; then
      # If not auto install Prompt for installation if any tool is missing and -y flag is not provided
      # zsh read format
      echo ""
      read "response?Do you want to install the missing tools (y/N)?"
      if [[ ! $response =~ ^[Yy]$ ]]; then
        echo_fail "Installation aborted."
        echo_info "For more information on how install manually: $MANUAL_INSTALL_LINK"
        exit 0
      fi # response
    fi # auto install
    echo_info "Installing pre-requisites for MacOS..."
    # If brew does not exist => install it
    if [ "${install_status["brew"]}" == "not installed" ]; then
      echo_info "Installing brew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install kubectl helm python
  else 
    # this probably will never be reached
    echo_error "System not supported ($PLATFORM)."
    exit 1
  fi # else
fi # command missing

# Verify installations 

# Verify kubectl functionality
not_working=false

echo_info "Verifying commands are working..."
if ! kubectl version &> /dev/null; then
  echo_error "The kubectl command ($(command -v "kubectl")) is not working properly."
  echo_error "Installation documentation:"
  echo_error "  - For Linux: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
  echo_error "  - For macOS: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/"
  not_working=true
else 
  echo_success "kubectl is working"
fi

# Verify helm functionality
if ! helm version &> /dev/null; then
  echo_error "The helm command ($(command -v "helm")) is not working properly."
  echo_error "Installation documentation:"
  echo_error "          https://helm.sh/docs/intro/install/"
  not_working=true

else 
  echo_success "helm is working"
fi

if [ "$not_working" = true ]; then
  echo_error "Some of the commands are not working."
  exit_error 3
fi 

#
# Install magasin helm charts in the kubernetes cluster
# $1 = chart name
#
function install_chart { 
  local chart=$1

  echo_debug "Install_chart $chart"
  
  if [[ -n "$REALM_POSTFIX" ]]; then
    # realm postfix is not empty
    namespace="$REALM_PREFIX-$chart-$REALM_POSTFIX"
  else
    # realm postfix is empty
    namespace="$REALM_PREFIX-$chart"
  fi

  echo_info "Installing magasin/$chart in the namespace $namespace." 
  values_helm_arg=""
  values_file="$VALUES_FOLDER$chart.yaml"
  echo_debug "values_file = $values_file"
  
  # check if $chart.yaml file exists
  if [ -f "$values_file" ]; then
    echo_success "Custom values file for $chart exists ($values_file)"
    # the -f option in helm allows you to set custom values
    # Include it as part of the 
    values_helm_arg="-f $values_file"
  else
    echo_info "Custom values file for $chart does NOT exist ($values_file)"
  fi
  # Check if the namespace already exists if so ask and warn the user.


  echo_info "helm install $chart magasin/$chart $values_helm_arg --namespace $namespace --create-namespace $HELM_DEBUG_FLAG"
  #helm install $chart magasin/$chart $values_helm_arg --namespace $namespace --create-namespace $HELM_DEBUG_FLAG
  if [[ $? -ne 0 ]]; then
    echo_error "Could not install  magasin/$chart in the namespace $namespace"
    #exit_error 7
  else 
    echo_success "magasin/$chart installed in namespace $namespace"
  fi


} 

echo_info "Adding magasin helm repo ($MAGASIN_HELM_REPO)..."
echo_info "Running: helm repo add $MAGASIN_HELM_REPO $HELM_DEBUG_FLAG"
helm repo add magasin $MAGASIN_HELM_REPO $HELM_DEBUG_FLAG
if [[ $? -ne 0 ]]; then
  echo_error "Could not add magasin repo."
  echo_error "If the repo already exists you can run the command 'helm repo remove magasin'"
  echo_error "and then re-run the installer again."
  exit_error 5
else 
  echo_success "magasin helm repo successfully added as 'magasin'."
fi

echo_info "Updating magasin helm repo ($MAGASIN_HELM_REPO)..."
helm repo update magasin
if [[ $? -ne 0 ]]; then
  echo_error "Could not update magasin repo."
  exit_error 6
else 
  echo_success "magasin helm repo updated successfully"
fi


install_chart drill
install_chart daskhub
install_chart dagster
install_chart superset

#
# Add a configmap with a json with some metadata
# 
echo_info "Creating the magasin realm namespace."
echo_info "kubectl create namespace $REALM_ARG"
kubectl create namespace $REALM_ARG