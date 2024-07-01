#!/bin/bash

sudo dnf update -y

sudo dnf install java-17-amazon-corretto-devel -y


sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade


sudo yum install jenkins -y

sleep 20

sudo systemctl daemon-reload

sleep 10

# Start Jenkins services
sudo systemctl enable jenkins.service

sleep 10


sudo systemctl stop jenkins.service

sleep 5

sudo systemctl start jenkins.service