#!/bin/sh

# Usage
# ./create_bucket.sh [optional:bucket-name]
#
#
# This script: 
#  1. creates a bucket (default: magasinbucket if no bucket-name is provided )
#  2. Creates a new user
#  3. Assigns the bucket to the new user. 
#
# Notes:
#  1. If an error appears "Client already exists", run
#
#     kubectl delete pod minio-client
#
#  2. The script needs write permissions in the current folder
#
############# CONFIG ########################

#Default namespace
NAMESPACE="magasin-tenant"

# Some random strings 20 an 5 chars respectively.
RND20=`openssl rand -hex 20`
RND5=`openssl rand -hex 5`

#
# Bucket name that will be created 
# You can pass it as the first argument when calling this script
#
DEFAULT_BUCKET_NAME="magasin-$RND5"

# Magasin user and password
# TODO use secrets
MAGASIN_USER="magasin-$RND5"
#
# a random password of 40 chars base64
#
MAGASIN_PASSWORD=`openssl rand -base64 40`

# A file that is used in the script to temporary keep
# an access token that will be used by Drill.

TMP_ACCESS_TOKEN_FILE="./tmp-access-token-$RND20.json" 

# Json file that is used as template
# for creating a storage connection in drill
#
# This script will create a copy named minio-drill.json 
# replace the text surrounded by ** **

# - **BUCKET_NAME**
# - **MAGASIN_USER**
# - **MAGASIN_PASSWORD**
#
# The configuration options names are available in the section "General S3A Client configuration"
# of this link (note it is in XML): 
# https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html
# For example the property fs.s3a.connection.ssl.enabled:
#
# <property>
#  <name>fs.s3a.connection.ssl.enabled</name>
#  <value>true</value>
#  <description>Enables or disables SSL connections to S3.</description>
# </property>
#
# NOTE: The template assumes 
#  - ssl disabled
#  - the endpoint access to the server is minio.default.svc.cluster.local:9000 
# 
MINIO_DRILL_STORAGE_TEMPLATE_FILE='./minio-drill-storage-template.json'

TMP_MINIO_DRILL_STORAGE_FILE="./minio-drill-storage-$RND5.json"

#
# Template of MINIO policy file to assign permissions
#
# The only item replaced is **BUCKET_NAME**
#
MINIO_DRILL_POLICY_TEMPLATE_FILE='./minio-drill-policy-template.json'

MINIO_DRILL_POLICY_FILE="./minio-drill-policy-$RND5.json"

############################## END OF CONFIG

BUCKET_NAME=$DEFAULT_BUCKET_NAME

if [ -z "$1" ]
  then
    echo "No bucket name provided as argument, using $BUCKET_NAME"
   else
      BUCKET_NAME=$1
      echo "Bucket name to be created $BUCKET_NAME"
      MAGASIN_USER=$1-user

fi
echo "Useername to be created $MAGASIN_USER"
#
# Test 
#
./mc.sh "admin info minio"

#
# Create the bucket
#
# https://min.io/docs/minio/linux/reference/minio-mc/mc-mb.html


echo "\n\nCreating magasin bucket $BUCKET_NAME"
./mc.sh "mb minio/$BUCKET_NAME"

#
# Create a user and a group to programatically to the bucket
# 
# https://min.io/docs/minio/linux/administration/identity-access-management/minio-user-management.html#access-keys
#
# First create a user in minio user: magasinuser password: magasin password
#

echo "\n\nCreating magasin user $MAGASIN_USER"
./mc.sh "admin user add minio $MAGASIN_USER $MAGASIN_PASSWORD"  

echo "\n\nSaving created magasin user $MAGASIN_USER and password in magasin-secrets"
# delete secret in case it exist
kubectl delete secret magasin
# create the secret
kubectl create secret generic magasin \
  --from-literal=minio-drill-bucket="$BUCKET_NAME" \
  --from-literal=minio-drill-user=$MAGASIN_USER \
  --from-literal=minio-drill-password="$MAGASIN_PASSWORD"


echo "\n\nCreating the group 'drill' that will have read only permissions to the buckets"
./mc.sh "admin group add minio drill $MAGASIN_USER"

echo "\n\nAdding readonly permission to drill group"
./mc.sh "admin policy set minio readonly group=drill"

# TODO
# Assign policies to the magasin user
#
# https://min.io/docs/minio/linux/administration/identity-access-management/policy-based-access-control.html#minio-policy
#
#echo "\n\nAssign access to the bucket to the drill through minio policies"

#cp  $MINIO_DRILL_POLICY_TEMPLATE_FILE minio-drill-policy.json
#REGEXP="s/\*\*BUCKET\_NAME\*\*/$BUCKET_NAME/g"
#sed -i '' $REGEXP minio-drill-policy.json
#./mc.sh "admin policy set"

#
# Create the service account linked to the magasin user
#

# minio client uses color output which messes up the text, so we disable it.
export CLICOLOR=0
echo "\n\nCreating magasin service account accesskey and secret"
echo "Temporarily saving the file in current working directory `pwd`/$TMP_ACCESS_TOKEN_FILE . This file will be deleted at the end of the script "
./mc.sh "admin user svcacct add minio $MAGASIN_USER --json --no-color"  > $TMP_ACCESS_TOKEN_FILE
# reenable color
export CLICOLOR=1

# This command outputs something like: 
#./mc.sh "admin user svcacct add minio magasinuser --json"
#If you don't see a command prompt, try pressing enter.
#Added `minio` successfully.
# 06:20:04.71 INFO  ==> ** MinIO Client setup finished! **
#
# {
# "status": "success",
# "accessKey": "0Q9GOUCBWFKCYCAS4WVW",
# "secretKey": "DGlCgt4zyjK+52IsXcUHcvNBHtrH54o2JxytppVD",
# "accountStatus": "enabled"
# }
# pod "minio-client" deleted
# 
# From this file we need the access key and the secret key
# which are used to connect Apache Drill to the minio bucket.
#
# this command gets the accessKey value from the json file
ACCESS_KEY=`cat $TMP_ACCESS_TOKEN_FILE | grep accessKey | awk -F '"' '{print $4}'`
# this command gets the secret key from the json file
SECRET_KEY=`cat $TMP_ACCESS_TOKEN_FILE | grep secretKey | awk -F '"' '{print $4}'`

#
# Generate the S3A drill configuration json file.
# 

# Replace values **BUCKET**, **ACCESS_KEY** and **SECRET_KEY** with the generated values
cp $MINIO_DRILL_STORAGE_TEMPLATE_FILE $TMP_MINIO_DRILL_STORAGE_FILE
REGEXP="s/\*\*BUCKET\_NAME\*\*/$BUCKET_NAME/g"
sed -i '' $REGEXP $TMP_MINIO_DRILL_STORAGE_FILE

REGEXP="s/\*\*ACCESS\_KEY\*\*/$ACCESS_KEY/g"
sed -i '' $REGEXP $TMP_MINIO_DRILL_STORAGE_FILE

REGEXP="s/\*\*SECRET\_KEY\*\*/$SECRET_KEY/g"
sed -i '' $REGEXP $TMP_MINIO_DRILL_STORAGE_FILE

REGEXP="s/\*\*NAMESPACE\*\*/$NAMESPACE/g"
sed -i '' $REGEXP $TMP_MINIO_DRILL_STORAGE_FILE



# delete secret in case it does exist
kubectl delete secret magasin-minio-drill
kubectl create secret generic magasin-minio-drill --from-file=minio-drill-storage-$BUCKET_NAME=./$TMP_MINIO_DRILL_STORAGE_FILE


#echo "Created the secret file $TMP_MINIO_DRILL_STORAGE_FILE. Use this file " 

echo "\n\nDeleting temporary file: $TMP_ACCESS_TOKEN_FILE"
rm  $TMP_ACCESS_TOKEN_FILE

# TODO - Remove for PRD
echo "\n\nDeleting temporary file: $TMP_MINIO_DRILL_STORAGE_FILE"
rm $TMP_MINIO_DRILL_STORAGE_FILE

echo "Done!"

echo "----------------------------------------------------------------------"
echo " To get the credentials of the magasin user, use the following commands:"
echo ""
echo "     kubectl get secret magasin -o jsonpath='{.data}'"
echo "     kubectl get secret magasin -o jsonpath='{.data.minio-drill-user}' | base64 -d"
echo "     kubectl get secret magasin -o jsonpath='{.data.minio-drill-password}' | base64 -d"
echo ""
echo "NOTE if you re-run this script and the user '$MAGASIN_USER' already existes the password in MinIO won't be updated. You need to delete the user $MAGASIN_USER before re-run."
echo ""
echo "To get the values of the configuration needed to set the connection" 
echo "between MinIO and Apache drill use this command:"
echo ""
echo "     kubectl get secret magasin-minio-drill -o jsonpath='{.data.minio-drill-storage-$BUCKET_NAME}' | base64 -d"
echo ""
echo ""
echo "----------------------------------"
echo "Bucket name: $BUCKET_NAME"
echo "MinIO User created: $MAGASIN_USER"
echo "----------------------------------"

# https://min.io/docs/minio/linux/reference/minio-mc/mc-cp.html#command-mc.cp
#./mc.sh "cp ./sample-data/* minio/$BUCKET_NAME"
