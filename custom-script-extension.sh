#!/bin/bash

apt-get update -y && apt-get upgrade -y
apt-get install -y nginx
echo "Hello World from VMSS instance: ${HOSTNAME}. Using Custom Script Extensions!" | sudo tee -a /var/www/html/index.html