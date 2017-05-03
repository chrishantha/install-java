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

function help {
    echo ""
    echo "Usage: "
    echo "uninstall-java.sh -p <java_dist_dir>"
    echo ""
    echo "-p: Java distribution directory"
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


while getopts "p:" opts
do
  case $opts in
    p)
        java_dist_dir=${OPTARG}
        ;;
    \?)
        help
        exit 1
        ;;
  esac
done

if [[ ! -f $java_dist_dir/bin/java ]]; then
    echo "Please specify a valid java distribution directory"
    help
    exit 1
fi

# Run update-alternatives commands

commands=( "jar" "java" "javac" "javadoc" "javah" "javap" "javaws" "jcmd" "jconsole" "jarsigner" "jhat" "jinfo" "jmap" "jmc" "jps" "jstack" "jstat" "jstatd" "jvisualvm" "keytool" "policytool" "wsgen" "wsimport" )

if (confirm "Run update-alternatives commands?"); then
    echo "Running update-alternatives --remove for ${commands[@]} mozilla-javaplugin.so"

    for i in "${commands[@]}"
    do
        sudo update-alternatives --remove "$i" "$java_dist_dir/bin/$i"
    done

    if [[ -d "/usr/lib/mozilla/plugins/" ]]; then
        sudo update-alternatives --remove "mozilla-javaplugin.so" "$java_dist_dir/jre/lib/amd64/libnpjp2.so"
    fi
fi

if (confirm "Remove directory '$java_dist_dir'?"); then
    rm -rf $java_dist_dir
fi