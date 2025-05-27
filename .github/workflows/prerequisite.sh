#!/bin/bash
apt-get -y update

echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "install AWS CLI, ZIP, SSH & Git library"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
apt-get update && apt-get install -y awscli zip openssh-client

echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
echo "Zipping the code to artifact.zip"
echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
zip -q -r /tmp/artifact.zip * # package up the application for deployment.
