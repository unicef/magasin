#!/bin/bash
# Gets all the service hosts in the cluster

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install it and configure it for your Kubernetes cluster."
    exit 1
fi

# Get cluster domain suffix from kubeconfig
#cluster_domain=$(kubectl config view -o=jsonpath='{.clusters[0].cluster.server}' | awk -F[/:] '{print $4}')
# Todo dynamic
cluster_domain="svc.cluster.local"

# Get all service names in all namespaces
services=$(kubectl get services --all-namespaces -o json | jq -r '.items[] | "\(.metadata.name).\(.metadata.namespace)'".$cluster_domain"'"')

# Print the result
echo "Services in the Kubernetes cluster:"
echo "$services"