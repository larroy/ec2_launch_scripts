#!/usr/bin/env bash

#
# Run this script in GPU instances to install nvidia drivers and nvidia-docker
#
set -exuo pipefail

sudo add-apt-repository -y ppa:graphics-drivers/ppa

curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update

sudo apt-get -y install nvidia-driver-418
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd


wget "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-ubuntu1804-10-1-local-10.1.105-418.39_1.0-1_amd64.deb"
apt-key add /var/cuda-repo-10-1-local-10.1.105-418.39/7fa2af80.pub
apt-get update
apt-get install cuda
