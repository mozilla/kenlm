#!/bin/bash
sleep 30
apt-get update
apt-get -y install g++
apt-get -y install cmake
apt-get -y install libbz2-dev
apt-get -y install liblzma-dev
apt-get -y install libboost-all-dev
export EIGEN3_ROOT=$HOME/eigen-eigen-07105f7124f9
echo export EIGEN3_ROOT=$EIGEN3_ROOT >>.bashrc
wget -O - https://bitbucket.org/eigen/eigen/get/3.2.8.tar.bz2 |tar xj
git clone https://github.com/mozilla/kenlm.git
cd kenlm
mkdir -p build
cd build
cmake ..
make -j 4
