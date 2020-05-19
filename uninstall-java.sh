#!/bin/bash
# Copyright 2015 M. Isuru Tharanga Chrishantha Perera
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Script for uninstalling Java
# ----------------------------------------------------------------------------

java_dist_dir=""

function usage() {
    echo ""
    echo "Usage: "
    echo "uninstall-java.sh -p <java_dist_dir>"
    echo ""
    echo "-p: Java distribution directory."
    echo "-h: Display this help and exit."
    echo ""
}

function confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure?} [y/N] " response
    case $response in
    [yY][eE][sS] | [yY])
        true
        ;;
    *)
        false
        ;;
    esac
}

# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"
    echo "sudo $0"
    exit 9
fi

while getopts "p:h" opts; do
    case $opts in
    p)
        java_dist_dir=${OPTARG}
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        usage
        exit 1
        ;;
    esac
done

if [[ -z $java_dist_dir ]]; then
    echo "Please provide Java installation directory."
fi

echo "Uninstalling: $java_dist_dir"

if [[ ! -f $java_dist_dir/bin/java ]]; then
    echo "Please specify a valid Java distribution directory"
    exit 1
fi

# Run update-alternatives commands
if (confirm "Run update-alternatives commands?"); then
    echo "Running update-alternatives..."
    update-alternatives --remove java ${java_dist_dir}/bin/java
fi

if (confirm "Remove directory '$java_dist_dir'?"); then
    rm -rf $java_dist_dir
fi

jdk_major_version=""

if [[ $java_dist_dir =~ .*jdk1\.([0-9]*).* ]]; then
    jdk_major_version=$(echo $java_dist_dir | sed -nE 's/.*jdk1\.([0-9]*).*/\1/p')
elif [[ $java_dist_dir =~ .*jdk-([0-9]*).* ]]; then
    jdk_major_version=$(echo $java_dist_dir | sed -nE 's/.*jdk-([0-9]*).*/\1/p')
fi

applications_dir="$HOME/.local/share/applications"
jmc_shortcut_file="$applications_dir/jmc_$jdk_major_version.desktop"

if [ -f $jmc_shortcut_file ] && (confirm "Remove JMC shortcut?"); then
    rm $jmc_shortcut_file
fi
