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
java_dir=""

function help {
    echo ""
    echo "Usage: "
    echo "install-java.sh -f <java_dist> [-p] <java_dir>"
    echo ""
    echo "-f: The jdk tar.gz file"
    echo "-p: Java installation directory"
    echo ""
}

confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure?} [y/N] " response
    case $response in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Make sure the script is running as root.
if [ "$UID" -ne "0" ]; then
    echo "You must be root to run $0. Try following"; echo "sudo $0";
    exit 9
fi


while getopts "f:p:" opts
do
  case $opts in
    f)
        java_dist=${OPTARG}
        ;;
    p)
        java_dir=${OPTARG}
        ;;
    \?)
        help
        exit 1
        ;;
  esac
done

if [[ ! -f $java_dist ]]; then
    echo "Please specify the java distribution file (tar.gz)"
    help
    exit 1
fi

#If no directory was provided, we need to create the default one
if [[ ! -d $java_dir ]]; then
    java_dir="/usr/lib/jvm"
    mkdir -p $java_dir
fi

#Validate java directory
if [[ ! -d $java_dir ]]; then
    echo "Please specify a valid java installation directory"
    exit 1
fi

# Extract Java Distribution

java_dist_filename=$(basename $java_dist)

dirname=$(echo $java_dist_filename | sed 's/jdk-\([78]\)u\([0-9]\{2,3\}\)-linux.*/jdk1.\1.0_\2/')

extracted_dirname=$java_dir"/"$dirname

if [[ ! -d $extracted_dirname ]]; then
    echo "Extracting $java_dist to $java_dir"
    tar -xof $java_dist -C $java_dir
    echo "JDK is extracted to $extracted_dirname"
else 
    echo "JDK is already extracted to $extracted_dirname"
fi


if [[ ! -f $extracted_dirname"/bin/java" ]]; then
    echo "Couldn't check the extracted directory. Please check the installation script"
    exit 1
fi

# Install Demos

demos_dist=$(dirname $java_dist)/$(echo $java_dist_filename | sed 's/jdk-\([78]u[0-9]\{2,3\}\)-linux-\(.*\).tar.gz/jdk-\1-linux-\2-demos.tar.gz/')

if [[ -f $demos_dist && ! -d $extracted_dirname/demo ]]; then
    # No demo directory
    if (confirm "Extract demos?"); then
        echo "Extracting $demos_dist to $java_dir"
        tar -xf $demos_dist -C $java_dir
    fi
fi

# Install Unlimited JCE Policy

unlimited_jce_policy_dist=""

if [[ "$java_dist_filename" =~ ^jdk-7.* ]]; then
    unlimited_jce_policy_dist="$(dirname $java_dist)/UnlimitedJCEPolicyJDK7.zip"
elif [[ "$java_dist_filename" =~ ^jdk-8.*  ]]; then
    unlimited_jce_policy_dist="$(dirname $java_dist)/jce_policy-8.zip"
fi

if [[ -f $unlimited_jce_policy_dist ]]; then
    if (confirm "Install Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files?"); then
        echo "Extracting policy jars in $unlimited_jce_policy_dist to $extracted_dirname/jre/lib/security"
        unzip -j -o $unlimited_jce_policy_dist *.jar -d $extracted_dirname/jre/lib/security
    fi
fi

# Run update-alternatives commands

commands=( "jar" "java" "javac" "javadoc" "javah" "javap" "javaws" "jcmd" "jconsole" "jarsigner" "jhat" "jinfo" "jmap" "jmc" "jps" "jstack" "jstat" "jstatd" "jvisualvm" "keytool" "policytool" "wsgen" "wsimport" )

if (confirm "Run update-alternatives commands?"); then
    echo "Running update-alternatives --install and --config for ${commands[@]} mozilla-javaplugin.so"

    for i in "${commands[@]}"
    do
        command_path=$extracted_dirname/bin/$i
        sudo update-alternatives --install "/usr/bin/$i" "$i" "$command_path" 10000
        sudo update-alternatives --set "$i" "$command_path"
    done

    if [[ -d "/usr/lib/mozilla/plugins/" ]]; then
        lib_path=$extracted_dirname/jre/lib/amd64/libnpjp2.so
        sudo update-alternatives --install "/usr/lib/mozilla/plugins/libjavaplugin.so" "mozilla-javaplugin.so" "$lib_path" 10000
        sudo update-alternatives --set "mozilla-javaplugin.so" "$lib_path"
    fi
fi

# Configure Java Mission Control
# Commented following configuration as the Welcome page is working in latest JMC included in Java 8u45 and 7u80.
# missioncontrol_config=$extracted_dirname/lib/missioncontrol/configuration/config.ini

# if ( (! grep -q mozilla "$missioncontrol_config") && confirm "Change default browser in Java Mission Control to Mozilla?"); then
#     echo org.eclipse.swt.browser.DefaultType=mozilla >> $missioncontrol_config
# fi


# Create system preferences directory
java_system_prefs_dir="/etc/.java/.systemPrefs"
if [[ ! -d $java_system_prefs_dir ]]; then
    if (confirm "Create Java System Prefs Directory and change ownership to $SUDO_USER:$SUDO_USER?"); then
        echo "Creating $java_system_prefs_dir"
        mkdir -p $java_system_prefs_dir
        chown -R $SUDO_USER:$SUDO_USER $java_system_prefs_dir
    fi
fi

if (confirm "Do you want to set JAVA_HOME environment variable?"); then
    if grep -q "export JAVA_HOME=.*" ~/.bashrc; then
        sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$extracted_dirname|" ~/.bashrc
    else
        echo "export JAVA_HOME=$extracted_dirname" >>  ~/.bashrc
    fi
fi
