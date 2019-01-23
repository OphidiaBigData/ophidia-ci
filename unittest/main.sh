#!/bin/bash

#
#    Ophidia CI
#    Copyright (C) 2013-2019 CMCC Foundation
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

if [ $# -ne 3 ]
then
        echo "The following arguments are required: buildtype (master, devel, etc.), workspace (where there are the sources), distro (centos7, ubuntu18)"
        exit 1
fi

buildtype=$1
WORKSPACE=$2
distro=$3

case "${distro}" in
        centos7)
			dist='el7.centos'
            ;;         
        ubuntu18)
			dist='debian'
            ;;         
        *)
            echo "Distro can be centos7 or ubunutu18"
            exit 1
esac

# Unit test for Ophidia Server

cd $WORKSPACE
git checkout ${buildtype}

./bootstrap
if [ ${dist} = 'el7.centos' ]
then
    ./configure --prefix=/usr/local/ophidia/oph-server --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework --with-soapcpp2-path=/usr/local/ophidia/extra --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia  --with-matheval-path=/usr/local/ophidia/extra/lib --with-cjose-path=/usr/local/ophidia/extra/lib  --enable-code-coverage > /dev/null
else
    ./configure --prefix=/usr/local/ophidia/oph-server --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework --with-soapcpp2-path=/usr/local/ophidia/extra --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia  --with-matheval-path=/usr/lib/x86_64-linux-gnu --with-cjose-path=/usr/local/ophidia/extra/lib  --enable-code-coverage > /dev/null
fi
make -s > /dev/null

make check > /dev/null

mkdir -p $WORKSPACE/OUTPUT
cp $WORKSPACE/test/test_output.trs $WORKSPACE/OUTPUT/

# Evaluate coverage of Ophidia Server test

cd $WORKSPACE

make check-code-coverage > /dev/null

gcovr . -x -o coverage.xml -e '.*curl' -e '.*server_test'

