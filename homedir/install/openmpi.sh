#!/usr/bin/env bash
set -ex
mkdir -p tmp
sudo chown -R ${USER}:${USER} tmp
wget "https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.1.tar.gz"
tar xzf openmpi-4.0.1.tar.gz
cd openmpi-4.0.1
./configure
make all install
sudo ldconfig
