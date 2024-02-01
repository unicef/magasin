#!/bin/sh

# TODO make the namespace dynamic

namespace="magasin-tenant"
#
# This is an alias of minio client to access it through the kubernetes cluster
# command uses a minio client docker to run the mc command
# (Minio Command Line) 
#
# Usage: mc.sh "minio client command"
# Example: mc.sh "admin info minio"
#
# If there is an error while running the command 
# the pod gets stuck and throws the error:
#
# Error from server (AlreadyExists): pods "minio-client" already exists
#
# In that case we can delete the pod ma nually.
#  $ kubectl delete pod minio-client --namespace magasin-tenant
#
# https://min.io/docs/minio/linux/reference/minio-mc.html
#
# Get the user and password for the admin of minio
#
env_config=$(kubectl get secret myminio-env-configuration -o jsonpath='{.data.config\.env}' --namespace $namespace  | base64 --decode)

#env_config contents should something like
#
#   export MINIO_ROOT_USER="user"
#   export MINIO_ROOT_PASSWORD="pass"
#
#

# Extract MINIO_ROOT_USER value
minio_root_user=$(echo "$env_config" | awk -F'"' '/MINIO_ROOT_USER=/{print $2}')

# Extract MINIO_ROOT_PASSWORD value
minio_root_password=$(echo "$env_config" | awk -F'"' '/MINIO_ROOT_PASSWORD=/{print $2}')

#
#
# This command uses a minio client docker to run the mc command
# (Minio Command Line) 
#
# https://min.io/docs/minio/linux/reference/minio-mc.html
#
# Note the docker image version was extracted from the documentation that a
# appears upon installation of minio. 
#
# TODO, make it dynamic based on minio server
#
#
#kubectl run --namespace $namespace minio-client \
#   --rm --tty -i --restart='Never' \
#   --env MINIO_SERVER_ROOT_USER=$minio_root_user \
#   --env MINIO_SERVER_ROOT_PASSWORD=$minio_root_password \
#   --env MINIO_SERVER_HOST=minio \
#   --image docker.io/bitnami/minio-client:2024.1.16-debian-11-r0 -- $1

echo $namespace
echo $minio_root_user $minio_root_password

kubectl create configmap minio-config \
    --from-literal=config.json='{
        "version": "10",
        "aliases": {
            "magasin": {
                "url": "https://myminio-hl.$namespace:9000",
                "accessKey": "$minio_root_user",
                "secretKey": "$minio_root_password",
                "api": "s3v4",
                "path": "auto"
            }
        }
    }'

set +x
kubectl run --namespace $namespace minio-client \
   --rm -i --restart='Never' \
   --env MINIO_SERVER_ROOT_USER=$minio_root_user \
   --env MINIO_SERVER_ROOT_PASSWORD=$minio_root_password \
   --env MINIO_SERVER_HOST=myminio-hl.$namespace \
   --env MINIO_SERVER_SCHEME=https \
   --env MINIO_SERVER_PORT_NUMBER=9000 \
   --image docker.io/bitnami/minio-client:2024.1.16-debian-11-r0 -- mc $1