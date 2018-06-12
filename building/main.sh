#!/bin/bash

#
#    Ophidia CI
#    Copyright (C) 2012-2016 CMCC Foundation
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

if [ $# -lt 1 ]
then
        echo "The following arguments are required: buildtype (master, devel, etc.)"
        echo "The following arguments are optional: package (terminal, primitives, io-server, server or analytics-framework)"
        exit 1
fi

buildtype=$1
package=$2

mkdir -p /usr/local/ophidia/src

# ophidia-primitives installation
if [ "${package}" == "primitives" ] || [ $# -eq 1 ]; then
	cd /usr/local/ophidia/src
	git clone https://github.com/OphidiaBigData/ophidia-primitives
	cd /usr/local/ophidia/src/ophidia-primitives
	git checkout ${buildtype}
	./bootstrap
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-primitives --with-matheval-path=/usr/local/ophidia/extra/lib > /dev/null
	echo `make -j2 -s > /dev/null`
	echo "Do not care previous possible errors"
	make -s > /dev/null
	make install -s > /dev/null
fi

# ophidia-io-server installation
if [ "${package}" == "io-server" ] || [ $# -eq 1 ]; then
	cd /usr/local/ophidia/src
	git clone https://github.com/OphidiaBigData/ophidia-io-server
	cd /usr/local/ophidia/src/ophidia-io-server
	git checkout ${buildtype}
	./bootstrap
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-io-server --with-netcdf-path=/usr/local/ophidia/extra > /dev/null
	echo `make -j2 -s > /dev/null`
	echo "Do not care previous possible errors"
	make -s > /dev/null
	make install -s > /dev/null
fi

# ophidia-analytics-framework installation
if [ "${package}" == "analytics-framework" ] || [ $# -eq 1 ]; then
	cd /usr/local/ophidia/src
	git clone https://github.com/OphidiaBigData/ophidia-analytics-framework
	cd /usr/local/ophidia/src/ophidia-analytics-framework
	git checkout ${buildtype}
	./bootstrap
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework --enable-parallel-netcdf --with-netcdf-path=/usr/local/ophidia/extra --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ophidiaio-server-path=/usr/local/ophidia/oph-cluster/oph-io-server > /dev/null
	echo `make -j2 -s > /dev/null`
	echo "Do not care previous possible errors"
	make -s > /dev/null
	make install -s > /dev/null
fi

# ophidia-server installation
if [ "${package}" == "server" ] || [ $# -eq 1 ]; then
	cd /usr/local/ophidia/src
	git clone https://github.com/OphidiaBigData/ophidia-server
	cd /usr/local/ophidia/src/ophidia-server
	git checkout ${buildtype}
	./bootstrap
	./configure --prefix=/usr/local/ophidia/oph-server --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework --with-soapcpp2-path=/usr/local/ophidia/extra --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia  --with-matheval-path=/usr/local/ophidia/extra/lib --with-cjose-path=/usr/local/ophidia/extra/lib > /dev/null
	echo `make -j2 -s > /dev/null`
	echo "Do not care previous possible errors"
	make -s > /dev/null
	make install -s > /dev/null
fi

# ophidia-terminal installation
if [ "${package}" == "terminal" ] || [ $# -eq 1 ]; then
	cd /usr/local/ophidia/src
	git clone https://github.com/OphidiaBigData/ophidia-terminal
	cd /usr/local/ophidia/src/ophidia-terminal
	git checkout ${buildtype}
	./bootstrap
	./configure --prefix=/usr/local/ophidia/oph-terminal > /dev/null
	echo `make -j2 -s > /dev/null`
	echo "Do not care previous possible errors"
	make -s > /dev/null
	make install -s > /dev/null
fi

