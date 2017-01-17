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

if [ $# -lt 4 ]
then
        echo "The following arguments are required: buildtype, distribution, path of rpm generator, path of specs"
		echo "The following arguments is optional: keep binary (yes - default is no)"
        exit 1
fi

dist=$2
pkg_path=$3
spec_path=$4
if [ -z "$4" ]; then 
keep_binary="no"
else
keep_binary=$4
fi

pkg_name="ophidia-analytics-framework"
repo_name="ophidia-analytics-framework"

source ${pkg_path}/scripts/functions.sh

build $1 ${pkg_path} ${repo_name} "--prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --enable-parallel-netcdf --with-netcdf-path=/usr/lib64/mpich --with-ophidiaio-server-path=/usr/local/ophidia/oph-cluster/oph-io-server"

mkdir -p /usr/local/ophidia/oph-cluster/oph-analytics-framework/share
cp -f LICENSE NOTICE.md /usr/local/ophidia/oph-cluster/oph-analytics-framework/share
mkdir -p /usr/local/ophidia/oph-cluster/oph-analytics-framework/log

#Remove unnecessary dirs
rm -rf /usr/local/ophidia/oph-cluster/oph-analytics-framework/include

#Copy configuration files
cp -r ${pkg_path}/common/oph-analytics-framework/etc/* /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/

copy_spec ${pkg_path} ${pkg_name} ${version} ${release} ${dist} ${spec_path}

mkdir ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /usr/local/ophidia/oph-cluster/oph-analytics-framework ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /var/www/html/ophidia/operators_xml ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /var/www/html/ophidia/img ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
rpmbuild --define "_topdir ${pkg_path}/rpmbuild" -bb -vv ${pkg_path}/rpmbuild/SPECS/${pkg_name}-${version}-${release}.${dist}.x86_64.spec

rm -rf ${pkg_path}/sources/$1/${repo_name}
if [ "${keep_binary}" != "yes" ]; then
	rm -rf /usr/local/ophidia/oph-cluster/oph-analytics-framework
	rm -rf /var/www/html/ophidia/{operators_xml,img}
fi
