#!/bin/bash

#
# Script to create a helm repository in the local filesystem and serve it in localhost.
# 
# A help respository is just a folder that is served through HTTP that contains
# a set of helm chart packages (tgz files will all the templates)
# and an index.yaml file that lists som metadata of these pacakges.
#  
# Launches http server in port 8000 (ie http://localhost:8000)
# The repo is created in ../local-repo/
# It uses the folder ../helm/ to extract the charts
# 
# This script is useful for testing the setup of not-yet-released versions of the magasin helm charts
# 
# /scripts/install/install-magasin.sh -u http://localhost:8000
#
#  References: 
# * https://helm.sh/docs/helm/helm_package/  
# * https://helm.sh/docs/helm/helm_repo/
#

# Debug
#set -x

# Get the path of the script.
script_dir=$(dirname "$(realpath "$0")")

# Path where the helm packages and index yaml will reside (../local-repo)
DEFAULT_REPO_DIR=$(realpath ../)/local-repo

# Path for the folder that holds the helm charts (../helm)
HELM_DIR=$(realpath "../helm")


# Actual path of the repo dir
REPO_DIR=$DEFAULT_REPO_DIR

LAUNCH_SERVER=true

while getopts ":n" opt; do
  case $opt in
    n)
      echo "** Do not launch server"
      LAUNCH_SERVER=false
      ;;
    h)
      usage $script_name
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      echo ""
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      ;;
  esac
done
echo "** Helm repository will be created in: $REPO_DIR"
echo "** The following folder should contain the charts: $HELM_DIR"

# Create the local repo dir if does not exist
if [ ! -d "$REPO_DIR" ]; then
    #mkdir -p "$REPO_DIR"
    echo "Local repository directory created: $REPO_DIR"
else
  echo "Local repository directory exits"
fi

# Check if helm dir exits
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

echo "helm repo index "$REPO_DIR" --merge "$REPO_DIR/index.yaml" --url "http://localhost:8000""
helm repo index "$REPO_DIR" --merge "$REPO_DIR/index.yaml" --url "http://localhost:8000"

if [[ "$LAUNCH_SERVER" == true ]]; then
  cd $REPO_DIR
  echo "Starting a local helm repo in http://localhost:8000"
  python3 -m http.server
  cd -
fi