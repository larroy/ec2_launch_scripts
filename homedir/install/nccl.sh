#!/usr/bin/env bash
set -exuo pipefail
# Needs NCCL from Nvidia developer portal
sudo dpkg -i nccl-repo-ubuntu1804-2.4.8-ga-cuda10.1_1-1_amd64.deb
sudo apt install libnccl2 libnccl-dev
