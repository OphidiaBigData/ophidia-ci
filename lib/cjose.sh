#!/bin/bash

PREVIOUS=$PWD
mkdir -p /usr/local/ophidia/src
cd /usr/local/ophidia/src
wget https://github.com/cisco/cjose/archive/0.4.1.tar.gz
tar -xzf 0.4.1.tar.gz
cd cjose-0.4.1
./configure --prefix=/usr/local/ophidia/extra > /dev/null
make > /dev/null
make install > /dev/null
cd $PREVIOUS

