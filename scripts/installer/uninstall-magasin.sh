#!/bin/bash
#
# Uninstall magasin from a kubernetes cluster
#


# Default REALM
REALM_ARG='magasin' # default
REALM_PREFIX='magasin'
REALM_POSTFIX=''

# Skip prompting
AUTO_INSTALL=false

# Only check if working
ONLY_CHECK=false

################### UTILITY FUNCTIONS #########


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

is_namespace() {
    local namespace="$1"
    local exists=$(kubectl get namespace "$namespace" >/dev/null 2>&1 && echo 1 || echo 0)
    echo "$exists"
}


#####################################


function usage {
  echo "Usage: $1 [-c] [-r realm_prefix-realm_postfix (magasin)] [-d] [-h]"
  echo ""
  echo "This script uninstall all magasin components from a kubernetes cluster"
  echo ""
  echo "Options:"
  echo "  -y  Skip prompting questions during uninstall."
  echo "  -c  Only check if all pre-requisites are installed in the local machine."
  echo "  -r  Realm prefix and suffix (default: magasin). Prefix and suffix are separated by '-'." 
  echo "        If more than one '-', the last one will be used as separator." 
  echo "        The realm 'magasin-new-dev' will set 'magasin-new' as prefix and 'dev' as suffix."
  echo "  -d  Enable debug mode (displays all commands run)."
  echo "  -h  Display this help message and exit."
  echo " "
  echo "Examples:"
  echo "   Only check if all requirements are installed"
  echo "      $1 -c "
  echo "   Uninstall 'magasin-dev' realm"
  echo "      $1 -r magasin-dev"
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
echo_info "REALM_ARG: $REALM_ARG"
echo_info "REALM_PREFIX: $REALM_PREFIX"
echo_info "REALM_POSTFIX: $REALM_POSTFIX"
echo_info "ONLY_CHECK: $ONLY_CHECK"
echo_info "PLATFORM: $PLATFORM"
echo_info "PATH: $PATH"
echo_info "HELM_DEBUG_FLAG: $HELM_DEBUG_FLAG"
echo "-----------"

#
# Verify kubectl and helm are working
#
not_working=false

echo_info "Verifying pre-required commands are working..."
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

# If -c option is set, then end.
if [[ "$ONLY_CHECK" == true ]]; then
  echo_debug "ONLY_CHECK=true"
  exit 0
fi

function uninstall_chart { 
  local chart=$1

  echo_info "Uninstalling chart $chart..."

  if [[ -n "$REALM_POSTFIX" ]]; then
    # realm postfix is not empty
    namespace="$REALM_PREFIX-$chart-$REALM_POSTFIX"
  else
    # realm postfix is empty
    namespace="$REALM_PREFIX-$chart"
  fi

  # Check if the namespace exists. If does not exist => stop
  if [ "$(is_namespace "$namespace")" -eq 0 ]; then
    echo_info "Namespace '$namespace' does not exist. Skipping $chart uninstallation."
    return
  fi


  echo_info "Uninstalling magasin/$chart in the namespace $namespace." 
  echo_info "helm uninstall $chart --namespace $namespace"
  helm uninstall $chart --namespace $namespace $HELM_DEBUG_FLAG
  if [[ $? -ne 0 ]]; then
    echo_fail "Could not uninstall  magasin/$chart in the namespace $namespace"
    #exit_error 7
  else 
    echo_success "magasin/$chart uninstalled from the namespace $namespace"
    echo_info "Removing namespace '$namespace' (be patient, it may take a while)..."
    kubectl delete namespace $namespace --wait=false 
    # Remove the namespace
    if [[ $? -ne 0 ]]; then
      echo_fail "Could not remove namespace $namespace"
    else 
       echo_success " Namespace $namespace successfully deleted"
    fi
  fi

}  

echo ""
echo_info "Starting magasin uninstallation..."
uninstall_chart drill
uninstall_chart daskhub
uninstall_chart superset
uninstall_chart dagster

# Remove the magasin realm namespace.
namespace=$REALM_ARG
# Check if the namespace exists. If does not exist => stop
if [ "$(is_namespace "$namespace")" -eq 0 ]; then
  echo_info "Namespace '$namespace' does not exist. Skipping removal"
else 
  kubectl delete namespace "$namespace"
  echo_success "Namespace '$namespace' deleted." 
fi

echo_success "magasin uninstallaltion finished"