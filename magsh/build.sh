#!/bin/bash

# Set default values
PROJECT=magsh
VERBOSE=false
TAG=""
PUSH=false

# Function to display usage
usage() {
  echo "Usage: $0 -r REGISTRY -v VERSION [-t TAG] [-p]"
  echo "  -r REGISTRY: The registry where the package will be published."
  echo "               Example: your username in dockerhub"
  echo "  -t TAG: Optional tag for the image. If not provided, defaults to the VERSION."
  echo "  -p: Optional flag to push the built image to the registry and enable multi-arch."
  echo 
  echo "  Example:"
  echo "         $0 -r merlos -t 0.1.0"
  echo "         $0 -r merlos -t 0.1.0-deb -p"
  echo 
  exit 1
}

# Parse options
while getopts ":r:v:t:p" opt; do
  case $opt in
    r)
      REGISTRY=$OPTARG
      ;;
    t)
      TAG=$OPTARG
      ;;
    p)
      PUSH=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Check if mandatory options are provided
if [[ -z $REGISTRY || -z $TAG ]]; then
  usage
fi


echo PROJECT=$PROJECT
echo REGISTRT=$REGISTRY
echo TAG=$TAG
echo PUSH=$PUSH 

set -x 
# Multi platform build
# https://docs.docker.com/build/guide/multi-platform/#buildx-setupa

# Check if magasin-builder buildx instance exists
if ! docker buildx inspect magasin-builder >/dev/null 2>&1; then
    echo "Creating magasin-builder buildx instance..."
    
    # Create magasin-builder buildx instance with docker-container driver
    docker buildx create --driver=docker-container --name=magasin-builder 
    
    if [ $? -eq 0 ]; then
        echo "magasin-builder buildx instance created successfully."
    else
        echo "Error: Failed to create magasin-builder buildx instance."
        exit 1
    fi
else
    echo "magasin-builder buildx instance already exists."
fi



# If there was no error building the image

if [[ $PUSH == true ]]; then
  echo "Pushing to registry ${REGISTRY}..."
  docker buildx build --builder=magasin-builder --platform linux/amd64,linux/arm64 --build-arg VERSION=${TAG} -t ${REGISTRY}/${PROJECT}:${TAG} -t ${REGISTRY}/${PROJECT}:latest --push  . 
  echo "Done"
else
  docker buildx build --builder=magasin-builder --build-arg VERSION=${TAG} -t ${REGISTRY}/${PROJECT}:${TAG} -t ${REGISTRY}/${PROJECT}:latest --load  .
  if [[ $? -eq 0 ]]; then
    echo "Build successful. Image not pushed to registry as -p flag not provided."
  fi
fi