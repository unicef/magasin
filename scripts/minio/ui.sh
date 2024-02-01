#!/bin/bash

#
# Shortcut script to forward the superset port and then launch the browser
# Tested on OSX (open url)
# 
# Requires kubectl to be pointing to the appropriate namespace

#
# Shortcut script to forward the superset port and then launch the browser
# Tested on OSX (open url)
# 

# Default namespace
NAMESPACE='magasin-tenant'

# Function to display usage
function display_usage() {
    echo "Usage: $0 [-n <namespace>] [-h]"
}

# Parse command-line arguments
while getopts ":n:h" opt; do
    case $opt in
        n)
            NAMESPACE="$OPTARG"
            ;;
        h)
            display_usage
            exit 0
            ;;
        \?)
            echo "Error: Invalid option -$OPTARG"
            display_usage
            exit 1
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            display_usage
            exit 1
            ;;
    esac
done
echo "Open https://localhost:9443"
kubectl port-forward svc/myminio-console 9443:9443 --namespace $NAMESPACE

