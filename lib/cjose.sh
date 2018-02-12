#!/bin/bash

wget https://github.com/cisco/cjose/archive/0.4.1.tar.gz
tar -xzf 0.4.1.tar.gz
cd cjose-0.4.1
./configure --prefix=/usr/local/ophidia/extra > /dev/null
make > /dev/null
make install > /dev/null
export PKG_CONFIG_PATH=/usr/local/ophidia/extra/lib/pkgconfig:$PKG_CONFIG_PATH

