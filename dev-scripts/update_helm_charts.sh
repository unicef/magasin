#/bin/bash
#
# Updates the helm charts of the folder /helm. 
# It downloads the latest official helm repo for each
# product and then it copies the chart to the helm subfolder
# Note that the update is done by removing the helm subfolders and
# updating the files.
# 
# TODO: find a more elegant way of doing this.
#
# Usage:
#       ./update_helm_charts.sh  
#
# See:
#     helm/README.md
#
#
# Stop the script if there is any error
set -e

# Displays the commands that are executed. Useful for debug
set -x

# Define a temporary folder to keep all charts
temp_charts=$(mktemp -d)

#
# Pulls from a repo a chart of a particular version within a specific folder
#
helm_pull() {
    # URL of the helm repo to pull the chart
    local repo_url=$1
    # How we're calling the repo locally
    local repo_name=$2
    # Name of the cahrt to download
    local chart_name=$3
    # Version of the chart to download
    local chart_version=$4
    # Folder in which the repo will be downloaded
    local output_dir=$5
    
    echo "Adding helm repo $repo_name ($repor_url)..."
    helm repo add $repo_name $repo_url
    echo Updating helm repo $repo_name...
    helm repo update $repo_name
    echo "Pulling chart $repo_name/$chart_name:$chart_version..."
    helm pull  $repo_name/$chart_name --version $chart_version --untar --untardir $output_dir
}

#
# Dagster
#
# To get the latest version number use the tag in the github repo
# https://github.com/dagster-io/dagster/releases Example: 1.5.9
helm_pull https://dagster-io.github.io/helm \
        dagster \
        dagster \
        1.5.9   \
        $temp_charts          

#
# Daskhub
#
# To get the version number use the release tag in the repo
# https://github.com/dask/helm-chart/tags. Example 2023.1.0
helm_pull https://helm.dask.org/ \
        dask \
        daskhub \
        2023.01.0 \
        $temp_charts          

#
# Apache Drill
#
# To get the version Use the latest release tag in the repo
# https://github.com/magasin-drill/tags
helm_pull https://unicef.github.io/magasin-drill \
        drill \
        drill \
        0.6.1 \
        $temp_charts          


#
# Superset 
#
# Search for superset-helm-chart version 
# https://github.com/apache/superset/tags
helm_pull https://apache.github.io/superset \
        superset \
        superset \
        0.10.15   \
        $temp_charts          

# Location where the new files are copied:
# TODO add command line option to select output directory
script_dir=$(dirname "$(realpath "$0")")
default_output_dir="$script_dir"/../helm/
output_dir=$default_output_dir

rm -rf $output_dir
cp -rp $temp_charts/ $output_dir


# Clean temporary folders
#rm -rf $temp_charts
