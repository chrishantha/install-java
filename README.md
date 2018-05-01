Oracle Java installation script for Linux
=========================================

"install-java.sh" is an installation script for setting up Oracle Java Development Kit on Debian based Linux Operating Systems.

I'm mainly using Ubuntu and therefore this script is tested only on Ubuntu versions.

## Prerequisites

The script uses "unzip" command. Therefore please make sure it is installed.

`sudo apt install unzip`

The "install-java.sh" script will not download the Java distribution. You need to [download JDK] from Oracle.

It is required to have all Java distributions in a single directory.

For example, if you want to install Java 7, following files should be downloaded and moved to a single directory.

 - jdk-7u80-linux-x64.tar.gz
 - jdk-7u80-linux-x64-demos.tar.gz
 - UnlimitedJCEPolicyJDK7.zip

Similarly for Java 8, following are the files required

 - jdk-8u172-linux-x64.tar.gz
 - jdk-8u172-linux-x64-demos.tar.gz
 - jce_policy-8.zip

For Java 9 and 10, you only need to have the Java binary distribution. For example,

 - jdk-10.0.1_linux-x64_bin.tar.gz

The Java Demos and Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy files are optional.

There are no demos from Java 9 upwards.

Since Java 9, default JCE policy files already allow for "unlimited" cryptographic strengths.

## Installation

The script needs to be run as root.

You need to provide the JDK distribution file (tar.gz) and the Java Installation Directory. The default value for Java installation directory is "/usr/lib/jvm"

```
Usage: 
install-java.sh -f <java_dist> [-p] <java_dir>

-f: The jdk tar.gz file
-p: Java installation directory
```

Example: Install Oracle JDK 7

`sudo ./install-java.sh -f ~/software/java/jdk-7u80-linux-x64.tar.gz`

Example: Install Oracle JDK 8

`sudo ./install-java.sh -f ~/software/java/jdk-8u172-linux-x64.tar.gz`

Example: Install Oracle JDK 9

`sudo ./install-java.sh -f ~/software/java/jdk-9.0.1_linux-x64_bin.tar.gz`

Example: Install Oracle JDK 10

`sudo ./install-java.sh -f ~/software/java/jdk-10.0.1_linux-x64_bin.tar.gz`

## Automate Java Installation

You can automate the Java installation script by using the `yes` command.

Example: Install Oracle JDK 8

`yes | sudo ./install-java.sh -f ~/software/java/jdk-8u172-linux-x64.tar.gz`

## Uninstallation

There is another script named "uninstall-java.sh" to uninstall Java. 

You need to provide Java distribution directory.

```
Usage: 
uninstall-java.sh -p <java_dist_dir>

-p: Java distribution directory
```

Example: Uninstall Oracle JDK 7

`sudo ./uninstall-java.sh -p /usr/lib/jvm/jdk1.7.0_80/`

## License

Copyright (C) 2014 M. Isuru Tharanga Chrishantha Perera

Licensed under the Apache License, Version 2.0

[download JDK]: http://www.oracle.com/technetwork/java/javase/downloads/index.html
