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
if [ -z "$5" ]; then 
keep_binary="no"
else
keep_binary=$5
fi

pkg_name="ophidia-server"
repo_name="ophidia-server"

source ${pkg_path}/scripts/functions.sh

build $1 ${pkg_path} ${repo_name} "--prefix=/usr/local/ophidia/oph-server --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework --with-soapcpp2-path=/usr/local/ophidia/extra --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-matheval-path=/usr/local/ophidia/extra/lib"

mkdir -p /usr/local/ophidia/oph-server/share
cp -f LICENSE NOTICE.md /usr/local/ophidia/oph-server/share
mkdir -p /usr/local/ophidia/oph-server/log
mkdir -p /var/www/html/ophidia/sessions
cp -r authz /usr/local/ophidia/oph-server/
mkdir -p /usr/local/ophidia/oph-server/authz/sessions
mkdir -p /usr/local/ophidia/oph-server/etc/cert

#Remove unnecessary include dir
rm -rf /usr/local/ophidia/oph-server/include

copy_spec ${pkg_path} ${pkg_name} ${version} ${release} ${dist} ${spec_path}

mkdir ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /usr/local/ophidia/oph-server ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /var/www/html/ophidia/*.php ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /var/www/html/ophidia/*.css ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
cp -r --parents /var/www/html/ophidia/sessions ${pkg_path}/rpmbuild/BUILDROOT/${pkg_name}-${version}-${release}.${dist}.x86_64
rpmbuild --define "_topdir ${pkg_path}/rpmbuild" -bb -vv ${pkg_path}/rpmbuild/SPECS/${pkg_name}-${version}-${release}.${dist}.x86_64.spec

rm -rf ${pkg_path}/sources/$1/${repo_name}
if [ "${keep_binary}" != "yes" ]; then
	rm -rf /usr/local/ophidia/oph-server
	rm -rf /var/www/html/ophidia/{*.php,*.css,sessions}
fi
