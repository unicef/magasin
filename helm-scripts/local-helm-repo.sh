#!/bin/bash

#
# Script to create a helm repository in the local filesystem and serve it in localhost.
# 
# A help repository is just a folder that is served through HTTP that contains
# a set of helm chart packages (tgz files with all the templates)
# and an index.yaml file that lists some metadata of these packages.
#  
# Launches http server by default on port 8000 (i.e., http://localhost:8000)
# The repository is created in ../_helm-repo/ by default
# It uses the folder ../helm/ to extract the charts
# 
# Options:
#  -p <port_number >to select the port (default 8000)
#  -n to avoid launching the http server
#   -r <repo_dir> change where the repo is created (defaults to ../_helm_repo). 
# 
# This script is useful for testing the setup of not-yet-released versions of the magasin helm charts
# 
# /scripts/install/install-magasin.sh -u http://localhost:8000
#
# References: 
# * https://helm.sh/docs/helm/helm_package/  
# * https://helm.sh/docs/helm/helm_repo/
#

# Debug (uncomment to debug the script)
#set -x

# Get the path of the script.
script_dir=$(dirname "$(realpath "$0")")

# Path for the folder that holds the helm charts (../helm)
HELM_DIR=$(realpath "../helm")

# Default port for the HTTP server
DEFAULT_PORT=8000

# Default behavior to launch the server
LAUNCH_SERVER=true

# Default port for the HTTP server
PORT=$DEFAULT_PORT

# Default repository directory
DEFAULT_REPO_DIR=$(realpath ../)/_helm-repo

# Actual path of the repository dir
REPO_DIR=$DEFAULT_REPO_DIR

# Function to display script usage
usage() {
    echo "Usage: $1 [-n] [-p port] [-r repo_dir]"
    echo "Options:"
    echo "  -n: Do not launch server"
    echo "  -p port: Specify the port number for the HTTP server (default: $DEFAULT_PORT)"
    echo "  -r repo_dir: Specify the repository directory (default: $DEFAULT_REPO_DIR)"
    echo "  "
    echo "Tip: If you are running simultaneously more than one instance of this script" 
    echo "Use -p and -r in the second instance. Otherwise it will overwrite the repo
    echo "of the first one."
    echo "set the -r option 
}

# Parse command-line options
while getopts ":np:r:" opt; do
  case $opt in
    n)
      echo "** Do not launch server"
      LAUNCH_SERVER=false
      ;;
    p)
      if [[ $OPTARG =~ ^[0-9]+$ && $OPTARG -ge 1 && $OPTARG -le 65535 ]]; then
        PORT=$OPTARG
      else
        echo "Error: Invalid port number. Port must be a number between 1 and 65535."
        usage "$script_name"
        exit 1
      fi
      ;;
    r)
      REPO_DIR=$OPTARG
      ;;
    h)
      usage "$script_name"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage "$script_name"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage "$script_name"
      exit 1
      ;;
  esac
done

echo "** Helm repository will be created in: $REPO_DIR"
echo "** The following folder should contain the charts: $HELM_DIR"
echo "** HTTP server will be launched on port: $PORT"

# Create the local repository dir if does not exist
if [ ! -d "$REPO_DIR" ]; then
    #mkdir -p "$REPO_DIR"
    echo "Local repository directory created: $REPO_DIR"
else
  echo "Local repository directory exits"
fi

# Check if helm dir exists
if [ ! -d "$HELM_DIR" ]; then
  echo "ERROR: Helm directory not found: $HELM_DIR"
  exit 2
fi

# Move into the helm directory
echo "Changing directory to $HELM_DIR"
cd "$HELM_DIR" || exit 1  

# Loop through each directory in the helm folder
for directory in */; do
    if [ -d "$directory" ]; then
        echo "Packaging Helm chart in $directory"
        echo "helm package "$directory" -d $REPO_DIR"  # Run helm package command for each directory
        helm package "$directory" -d $REPO_DIR  # Run helm package command for each directory
        fi
    done
cd -
echo "Returned to `pwd`"

echo "helm repo index "$REPO_DIR" --merge "$REPO_DIR/index.yaml" --url "http://localhost:$PORT""
helm repo index "$REPO_DIR" --merge "$REPO_DIR/index.yaml" --url "http://localhost:$PORT"

if [[ "$LAUNCH_SERVER" == true ]]; then
  cd $REPO_DIR
  echo "Starting a local helm repo in http://localhost:$PORT"
  python3 -m http.server $PORT
  cd -
fi
