#/bin/bash
#
# Updates the helm charts of the folder /helm. 
# It downloads the original github repos - 
# which generally have more contents other than the 
# helm chart and extracts the charts.
#
# The update is done by removing the helm subfolders and
# updating the files.
# 
# TODO: more elegant way of doing this.
#
# Usage:
#       ./update_helm_charts.sh  
#
# See:
#     helm/README.md
#
#

DAGSTER_TAG="1.5.6"
DASKHUB_TAG="main" # Tags not up to date...
SUPERSET_TAG="superset-helm-chart-0.10.14"

# Stop the script if there is any error
set -e

# Displays the commands that are executed. Useful for debug
set -x

# Create temporary folders
temp_clone=../.base_repos
temp_charts=$(mktemp -d)

# Location where the new files are copied:
script_dir=$(dirname "$(realpath "$0")")
default_output="$script_dir"/../helm/

#TODO add command line option to select output directory
output_dir=$default_output

# Clones or updates a local repo.
# If the repo exists in the target_folder(3), it updates it with the tag_name (1)
# If the repo does not exist, it clones the repo from the repository_url(2)
clone_or_update_repo() {
    local tag_name=$1
    local repository_url=$2
    local target_folder=$3

    if [ -d "$target_folder/.git" ]; then
        echo "Updating existing repository $repository_url in $target_folder to tag $tag_name"
        (cd "$target_folder" && git fetch && git checkout "$tag_name")
    else
        echo "Cloning repository $repository_url to $target_folder with tag $tag_name"
        git clone --branch "$tag_name" --single-branch "$repository_url" "$target_folder"
    fi
}

                    # Branch       # Repo url                             # Dest folder to update/clone
clone_or_update_repo $DAGSTER_TAG  https://github.com/dagster-io/dagster/ $temp_clone/dagster
clone_or_update_repo $DASKHUB_TAG  https://github.com/dask/helm-chart     $temp_clone/daskhub
clone_or_update_repo $SUPERSET_TAG https://github.com/apache/superset     $temp_clone/superset

#git clone https://github.com/dask/helm-chart $temp_clone/daskhub
#git clone https://github.com/apache/superset $temp_clone/superset
#git clone --branch=DAGSTER_TAG https://github.com/dagster-io/dagster/ $temp_clone/dagster



cp -r $temp_clone/daskhub/daskhub $temp_charts/
cp -r $temp_clone/superset/helm/superset $temp_charts/
cp -rp $temp_clone/dagster/helm/dagster $temp_charts/dagster

rm -rf $output_dir
cp -rp $temp_charts/ $output_dir


# Clean temporary folders
rm -rf $temp_charts
