#!/usr/bin/env bash
set -exuo pipefail
sudo apt remove --purge --auto-remove cmake

# Update CMAKE for correct cuda autotedetection: https://github.com/clab/dynet/issues/1457
version=3.14
build=0
mkdir -p ~/tmp
cd ~/tmp
wget https://cmake.org/files/v$version/cmake-$version.$build.tar.gz
tar -xzvf cmake-$version.$build.tar.gz
cd cmake-$version.$build/
./bootstrap
make -j$(nproc)
sudo make install

