#!/bin/bash

NAMESPACE="magasin"
YAML_FILE="debian.yaml"

while getopts ":duf:" opt; do
  case ${opt} in
    d ) # Deploy
      kubectl apply -f "$YAML_FILE" -n "$NAMESPACE"
      ;;
    u ) # Undeploy
      kubectl delete -f "$YAML_FILE" -n "$NAMESPACE"
      ;;
    f ) # Specify YAML file
      YAML_FILE=$OPTARG
      ;;
    \? ) echo "Usage: deploy_debian.sh [-d] [-u] [-f filename]"
      ;;
  esac
done
shift $((OPTIND -1))
