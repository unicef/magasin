#/bin/bash
#
# Updates the helm charts of the folder /helm. 
# It downloads the latest official helm repo for each
# product and then it copies the chart to the helm subfolder
# 
# Note that the update is done by removing the helm subfolders and
# updating the files.
# 
#
# Usage:
#       ./update_helm_charts.sh  [-o output_dir (default:../helm/)] -c config_file (default: ./update-helm-charts.conf)]  [-h]
#
# See:
#     helm/README.md
#
#
# The script does the following:
#  1. Adds the repo to the local helm (helm repo add superset https://helm.superset.io)
#  2. Updates the local repo (f.i. helm repo update superset)
#  3. Pulls the chart from the repo (f.i. superset/superset)
#  4. Copies the chart to the output directory (../helm/superset/)
#
## 
#
# Gets the directory where the script is located
script_dir=$(dirname "$(realpath "$0")")

#######################
# Default values
#
# Default config file with the helm charts to download
# it is relative to the script directory (f.i. if the script is in /home/user/magasin/helm-scripts, the default config file is /home/user/magasin/helm-scripts/update-helm-charts.config)
DEFAULT_CONFIG_FILE='update-helm-charts.config'

#
# Default output directory where the helm charts will be copied
# ATTENTION It is deleted and recreated every time the script is run
# it is relative to the script directory (f.i. if the script is in /home/user/magasin/helm-scripts, the default output directory is /home/user/magasin/helm/)
# Each chart will be copied on the chart name. For example if in the config file the chart_name is superset, the chart will be copied to /home/user/magasin/helm/superset
DEFAULT_OUTPUT_DIR='../helm'
#########################

# Set the default values to be used
config_file="$script_dir"/$DEFAULT_CONFIG_FILE
# base directory where the helm charts will be copied
output_dir="$script_dir"/$DEFAULT_OUTPUT_DIR


# Stop the script if there is any error
set -e

# Displays the commands that are executed. Useful for debug
#set -x



#
# Check current helm chart version
#
is_same_chart_version() {
    # Folder where the existing helm charts are located
    local helm_folder=$1
    # Name of the chart to check
    local chart_name=$2
    # Version of the chart to check
    local chart_version=$3
    result=0
    echo "Checking if the chart $chart_name is already the $chart_version version in folder ($helm_folder/$chart_name)..."
    # check if the chart is already the latest version
    if [ -d $helm_folder/$chart_name ]; then
        # get the current version of the chart
        # filter lines that start with "version:"" and get the second field that holds the version number
        current_version=$(cat $helm_folder/$chart_name/Chart.yaml | grep "^version:" | awk '{print $2}')
        echo  "** $chart_name current_version=$current_version"
        if [ $current_version == $chart_version ]; then
            echo "The chart $chart_name has already the  $chart_version"
            result=1
        fi
        echo "The chart $chart_name is not the $chart_version version"
    else
        echo "The chart $chart_name is not in the folder $helm_folder"
    fi
    return $result
}


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
    local download_dir=$5
    # Output_dir
    
    echo "Adding helm repo $repo_name ($repor_url)..."
    helm repo add $repo_name $repo_url
    echo Updating helm repo $repo_name...
    helm repo update $repo_name
    echo "Pulling chart $repo_name/$chart_name:$chart_version..."
    helm pull  $repo_name/$chart_name --version $chart_version --untar --untardir $download_dir
    # remove the current folder
    echo "Removing $output_dir/$chart_name..."
    rm -rf $output_dir/$chart_name
    # copy the new folder
    echo "Copying cache $download_dir/$chart_name to final folder $output_dir..."
    cp -rp $download_dir/$chart_name $output_dir
}


#
# Process the configuration file
# It reads the configuration file and returns an array with the arguments
#
process_config() {
    local config_file="$1"
    local -a result=()

    # Read arguments from the file and process each line
    while IFS= read -r line; do
        # Skip empty lines and lines starting with #
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        # Normalize spaces and tabs to a single space
        normalized_line=$(echo "$line" | tr -s '[:space:]' ' ')
        
        # Add the normalized line to the result array
        result+=("$normalized_line")
    done < "$config_file"

    # Return the result array
    echo "${result[@]}"
}

force=false

# Proccess arguments
# -o output_dir
# -c config_file
# -f force overwrite the chart if the version is the same
# -h help
while getopts "o:c:hf" opt; do
    case $opt in
        o)
            output_dir=$OPTARG
            ;;
        
        c)
            config_file=$OPTARG
            ;;
        f)
            force=true
            ;;
        h)
            echo "Usage: $0 [-o output_dir] [-c config_file] [-h]"
            echo "Options:"
            echo "  -o output_dir: Output directory where the helm charts will be copied. Default: $DEFAULT_OUTPUT_DIR"
            echo "  -c config_file: Configuration file with the helm charts to download. Default: $DEFAULT_CONFIG_FILE"
            echo "  -f: Force overwrite the chart if the version in the output dir exists and it is the same"
            echo "  -h: Show this help message"
            exit 0
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." 1>&2
            exit 1
            ;;
    esac
done


# Define a temporary folder to keep all charts
temp_charts=$(mktemp -d)

args_array=($(process_config "$config_file"))

echo args_array=${args_array[@]}
# Print the arguments for each run
for ((i=0; i<${#args_array[@]}; i+=4)); do
    repo_url="${args_array[i]}"
    repo_name="${args_array[i+1]}"
    chart_name="${args_array[i+2]}"
    chart_version="${args_array[i+3]}"
    # check if the local chart is already the latest version
    # if it is, skip the download
    if [ "$force" == false ]; then
        echo "Checking if the chart $chart_name is already the $chart_version version in folder ($output_dir/$chart_name)..."
        # check if the chart is already the latest version
        if [ -d $output_dir/$chart_name ]; then
            # filter lines that start with "version:"" and get the second field that holds the version number
            current_version=$(cat $output_dir/$chart_name/Chart.yaml | grep "^version:" | awk '{print $2}')
            echo  "** $chart_name current_version=$current_version"
            if [ $current_version == $chart_version ]; then
                echo "The chart $chart_name has already the  $chart_version"
                continue
            fi
            echo "The chart $chart_name is not the $chart_version version"
        else
            echo "The chart $chart_name is not in the folder $helm_folder"
        fi
    fi
    # pull the chart
    helm_pull $repo_url $repo_name $chart_name $chart_version $temp_charts

done


# remove the output directory and copy the new files
#echo "Removing $output_dir and copying the new files..."
# asks for confirmation before removing the directory

#rm -rf $output_dir
#cp -rp $temp_charts/ $output_dir


# Clean temporary folders
#rm -rf $temp_charts
