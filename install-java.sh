#!/bin/bash
# ----------------------------------------------------------------------------
# Description : Installation script for setting up Java on Linux
# Author      : M. Isuru Tharanga Chrishantha Perera
# ----------------------------------------------------------------------------

set -e

java_dist=""
java_dir="/usr/lib/jvm"

function help {
    echo ""
    echo "Usage: "
    echo "install_java.sh -f <java_dist> [-p] <java_dir>"
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


while getopts ":f:p" opts
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

if [[ ! -d $java_dir ]]; then
    echo "Please specify a valid java installation directory"
    exit 1
fi

#If no directory was provided, we need to create the default one
mkdir -p $java_dir

# Extract Java Distribution

java_dist_filename=$(basename $java_dist)

dirname=$(echo $java_dist_filename | sed 's/jdk-\([78]\)u\([0-9]\{2\}\)-linux.*/jdk1.\1.0_\2/')

extracted_dirname=$java_dir"/"$dirname

if [[ ! -d $extracted_dirname ]]; then
	echo "Extracting $java_dist to $java_dir"
	tar -xf $java_dist -C $java_dir
    echo "JDK is extracted to $extracted_dirname"
else 
    echo "JDK is already extracted to $extracted_dirname"
fi


if [[ ! -f $extracted_dirname"/bin/java" ]]; then
    echo "Couldn't check the extracted directory. Please check the installation script"
    exit 1
fi

# Install Demos

demos_dist=$(dirname $java_dist)/$(echo $java_dist_filename | sed 's/jdk-\([78]u[0-9]\{2\}\)-linux-\(.*\).tar.gz/jdk-\1-linux-\2-demos.tar.gz/')

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

commands=( "jar" "java" "javac" "javadoc" "javah" "javap" "javaws" "jcmd" "jconsole" "jarsigner" "jhat" "jinfo" "jmap" "jps" "jstack" "jstat" "jstatd" "keytool" "policytool" "wsgen" "wsimport" )

if (confirm "Run update-alternatives commands?"); then
	echo "Running update-alternatives --install for ${commands[@]} mozilla-javaplugin.so"

	for i in "${commands[@]}"
	do
		sudo update-alternatives --install "/usr/bin/$i" "$i" "$extracted_dirname/bin/$i" 1
	done

	sudo update-alternatives --install "/usr/lib/mozilla/plugins/libjavaplugin.so" "mozilla-javaplugin.so" "$extracted_dirname/jre/lib/amd64/libnpjp2.so" 1

	echo "Running update-alternatives --config"

	for i in "${commands[@]}"
	do
		sudo update-alternatives --config "$i"
	done

	sudo update-alternatives --config "mozilla-javaplugin.so"
fi

# Configure Java Mission Control

missioncontrol_config=$extracted_dirname/lib/missioncontrol/configuration/config.ini

if ( (! grep -q mozilla "$missioncontrol_config") && confirm "Change default browser in Java Mission Control to Mozilla?"); then
    echo org.eclipse.swt.browser.DefaultType=mozilla >> $missioncontrol_config
fi
