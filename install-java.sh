#!/bin/bash
# Copyright 2014 M. Isuru Tharanga Chrishantha Perera
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
# Installation script for setting up Java on Linux
# ----------------------------------------------------------------------------

java_dist=""
default_java_dir="/usr/lib/jvm"
java_dir="$default_java_dir"

function usage() {
    echo ""
    echo "This script will not download the Java distribution. You must download JDK tar.gz distribution. Then use this script to install it."
    echo "Usage: "
    echo "install-java.sh -f <java_dist> [-p <java_dir>]"
    echo ""
    echo "-f: The jdk tar.gz file."
    echo "-p: Java installation directory. Default: $default_java_dir."
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

while getopts "f:p:h" opts; do
    case $opts in
    f)
        java_dist=${OPTARG}
        ;;
    p)
        java_dir=${OPTARG}
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

if [[ ! -f $java_dist ]]; then
    echo "Please specify the Java distribution file."
    echo "Use -h for help."
    exit 1
fi

# Validate Java Distribution
java_dist_filename=$(basename $java_dist)

if [[ ${java_dist_filename: -7} != ".tar.gz" ]]; then
    echo "Java distribution must be a valid tar.gz file."
    exit 1
fi

# Create the default directory if user has not specified any other path
if [[ $java_dir == $default_java_dir ]]; then
    mkdir -p $java_dir
fi

#Validate java directory
if [[ ! -d $java_dir ]]; then
    echo "Please specify a valid Java installation directory."
    exit 1
fi

echo "Installing: $java_dist_filename"

# Check Java executable
java_exec="$(tar -tzf $java_dist | grep ^[^/]*/bin/java$ || echo "")"

if [[ -z $java_exec ]]; then
    echo "Could not find \"java\" executable in the distribution. Please specify a valid Java distribution."
    exit 1
fi

# JDK Directory with version
jdk_dir="$(echo $java_exec | cut -f1 -d"/")"
extracted_dirname=$java_dir"/"$jdk_dir

# Extract Java Distribution
if [[ ! -d $extracted_dirname ]]; then
    echo "Extracting $java_dist to $java_dir"
    tar -xof $java_dist -C $java_dir
    echo "JDK is extracted to $extracted_dirname"
else
    echo "WARN: JDK was not extracted to $java_dir. There is an existing directory with the name \"$jdk_dir\"."
    if ! (confirm "Do you want to continue?"); then
        exit 1
    fi
fi

if [[ ! -f "${extracted_dirname}/bin/java" ]]; then
    echo "ERROR: The path $extracted_dirname is not a valid Java installation."
    exit 1
fi

# Oracle JDK: 7 to 8
java_78_dir_regex="^jdk1\.([0-9]*).*$"
# Oracle JDK / OpenJDK / AdoptOpenJDK: 9 and upwards
java_9up_dir_regex="^jdk-([0-9]*).*$"

# JDK Major Version
jdk_major_version=""

if [[ $jdk_dir =~ $java_78_dir_regex ]]; then
    jdk_major_version=$(echo $jdk_dir | sed -nE "s/$java_78_dir_regex/\1/p")
else
    jdk_major_version=$(echo $jdk_dir | sed -nE "s/$java_9up_dir_regex/\1/p")
fi

# Install Demos

if [[ $jdk_dir =~ $java_78_dir_regex ]]; then
    # Demos are only available for Java 7 and 8
    demos_dist=$(dirname $java_dist)"/"$(echo $java_dist_filename | sed 's/\.tar\.gz/-demos\0/')
fi

if [[ -f $demos_dist && ! -d $extracted_dirname/demo ]]; then
    # No demo directory
    if (confirm "Extract demos?"); then
        echo "Extracting $demos_dist to $java_dir"
        tar -xf $demos_dist -C $java_dir
    fi
fi

# Install Unlimited JCE Policy (only for Oracle JDK 7 & 8)
# Java 9 and above: default JCE policy files already allow for \"unlimited\" cryptographic strengths.

unlimited_jce_policy_dist=""

if [[ $jdk_dir =~ ^jdk1\.7.* ]]; then
    unlimited_jce_policy_dist="$(dirname $java_dist)/UnlimitedJCEPolicyJDK7.zip"
elif [[ $jdk_dir =~ ^jdk1\.8.* ]]; then
    unlimited_jce_policy_dist="$(dirname $java_dist)/jce_policy-8.zip"
fi

if [[ -f $unlimited_jce_policy_dist ]]; then
    #Check whether unzip command exsits
    if ! command -v unzip >/dev/null 2>&1; then
        echo "Please install unzip (apt -y install unzip)."
        exit 1
    fi
    if (confirm "Install Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files?"); then
        echo "Extracting policy jars in $unlimited_jce_policy_dist to $extracted_dirname/jre/lib/security"
        unzip -j -o $unlimited_jce_policy_dist *.jar -d $extracted_dirname/jre/lib/security
    fi
fi

# Run update-alternatives commands
if (confirm "Run update-alternatives commands?"); then
    echo "Running update-alternatives..."
    cmd="update-alternatives --install /usr/bin/java java $extracted_dirname/bin/java 10000"
    declare -a commands=($(ls -1 ${extracted_dirname}/bin | grep -v ^java$))
    for command in "${commands[@]}"; do
        command_path=$extracted_dirname/bin/$command
        if [[ -x $command_path ]]; then
            cmd="$cmd --slave /usr/bin/$command $command $command_path"
        fi
    done
    lib_path=$extracted_dirname/jre/lib/amd64/libnpjp2.so
    if [[ -d "/usr/lib/mozilla/plugins/" ]] && [[ -f $lib_path ]]; then
        cmd="$cmd --slave /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so $lib_path"
    fi
    echo $cmd
    # Execute command
    $cmd
    update-alternatives --set java $extracted_dirname/bin/java
fi

# Create system preferences directory
java_system_prefs_dir="/etc/.java/.systemPrefs"
if [[ ! -d $java_system_prefs_dir ]]; then
    if (confirm "Create Java System Prefs Directory ($java_system_prefs_dir) and change ownership to $SUDO_USER:$SUDO_USER?"); then
        echo "Creating $java_system_prefs_dir"
        mkdir -p $java_system_prefs_dir
        chown -R $SUDO_USER:$SUDO_USER $java_system_prefs_dir
    fi
fi

USER_HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"

if [[ -d "$USER_HOME" ]] && (confirm "Do you want to set JAVA_HOME environment variable in $USER_HOME/.bashrc?"); then
    if grep -q "export JAVA_HOME=.*" $USER_HOME/.bashrc; then
        sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$extracted_dirname|" $USER_HOME/.bashrc
    else
        echo "export JAVA_HOME=$extracted_dirname" >>$USER_HOME/.bashrc
    fi
fi

applications_dir="$USER_HOME/.local/share/applications"

create_jmc_shortcut() {
    shortcut_file="$applications_dir/jmc_$jdk_major_version.desktop"
    cat <<_EOF_ >$shortcut_file
[Desktop Entry]
Name=Java $jdk_major_version: JMC
Comment=Oracle Java Mission Control for Java $jdk_major_version
Type=Application
Exec=$extracted_dirname/bin/jmc
Icon=$extracted_dirname/lib/missioncontrol/icon.xpm
Terminal=false
_EOF_
    chmod +x $shortcut_file
}

if [[ -d $applications_dir ]] && [[ -f $extracted_dirname/bin/jmc ]]; then
    if (confirm "Do you want to create a desktop shortcut to JMC?"); then
        create_jmc_shortcut
    fi
fi
