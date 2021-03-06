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

if [ $# -lt 3 ]
then
        echo "The following arguments are required: buildtype, path of package generator, path of control file"
		echo "The following arguments is optional: keep binary (yes - default is no)"
        exit 1
fi

pkg_path=$2
control_path=$3
if [ -z "$4" ]; then 
keep_binary="no"
else
keep_binary=$4
fi

pkg_name="ophidia-terminal"
repo_name="ophidia-terminal"

source ${pkg_path}/scripts/functions.sh

build $1 ${pkg_path} ${repo_name} "--prefix=/usr/local/ophidia/oph-terminal"

mkdir -p /usr/local/ophidia/oph-terminal/share
cp -f LICENSE NOTICE.md /usr/local/ophidia/oph-terminal/share

#Remove unnecessary dirs
rm -rf /usr/local/ophidia/oph-terminal/include

mkdir -p ${pkg_path}/${pkg_name}_${version}-${release}_amd64/DEBIAN

copy_control ${pkg_path} ${pkg_name} ${version} ${release} ${control_path}

cp -r --parents /usr/local/ophidia/oph-terminal ${pkg_path}/${pkg_name}_${version}-${release}_amd64

mkdir -p ${pkg_path}/${pkg_name}_${version}-${release}_amd64/usr/bin
ln -sf /usr/local/ophidia/oph-terminal/bin/oph_term ${pkg_path}/${pkg_name}_${version}-${release}_amd64/usr/bin/oph_term

dpkg-deb --build ${pkg_path}/${pkg_name}_${version}-${release}_amd64/ ${pkg_path}/debbuild/${pkg_name}_${version}-${release}_amd64.deb

rm -rf ${pkg_path}/sources/$1/${repo_name}
if [ "${keep_binary}" != "yes" ]; then
	rm -rf /usr/local/ophidia/oph-terminal
fi
rm -rf ${pkg_path}/${pkg_name}_${version}-${release}_amd64

