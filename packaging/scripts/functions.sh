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

function build {

	if [ $# -ne 4 ]
	then
		    echo "The following arguments are required: buildtype, path of package generator, repository name, configure args"
		    exit 1
	fi

	pkg_path=$2
	repo_name=$3
	config_args=$4

	cd ${pkg_path}/sources/$1
	rm -rf ${pkg_path}/sources/$1/${repo_name}
	git clone https://github.com/OphidiaBigData/${repo_name}.git
	cd ${pkg_path}/sources/$1/${repo_name}

	git checkout $1

	#Get version
	get_version

	./bootstrap
	./configure ${config_args} > /dev/null
	make -s > /dev/null
	if [ $? = 2 ]
	then
		echo "Compilation Error!"
		rm -rf ${pkg_path}/sources/$1/${repo_name}
		exit 1
	fi
	make install -s > /dev/null

}

function get_version {

	term_vers=(`git describe --tags | head -n 1 | grep -Po '(?<=v)[0-9.-]*'`)
	if [ "${term_vers}" = "" ]; then
		version=0	
		release=0
	else

		IFS='-' read -ra VERS <<< "$term_vers"
		version=${VERS[0]}
		if [ ${#VERS[@]} -eq 1 ]
			then release=0
			else release=${VERS[1]}
		fi
	fi
}

function copy_spec {

	if [ $# -ne 6 ]
	then
	        echo "The following arguments are required: path of package generator, package name, version, release number, distribution, path of spec"
		    exit 1
	fi

	version=$3
	release=$4
	dist=$5
	pkg_path=$1
	pkg_name=$2
	spec_path=$6

	cp ${spec_path}/${pkg_name}.spec ${pkg_path}/rpmbuild/SPECS/${pkg_name}-${version}-${release}.${dist}.x86_64.spec
	sed -i "s/\*\*VERSION\*\*/${version}/g" ${pkg_path}/rpmbuild/SPECS/${pkg_name}-${version}-${release}.${dist}.x86_64.spec
	sed -i "s/\*\*RELEASE\*\*/${release}/g" ${pkg_path}/rpmbuild/SPECS/${pkg_name}-${version}-${release}.${dist}.x86_64.spec

}

function copy_control {

	if [ $# -ne 5 ]
	then
	        echo "The following arguments are required: path of package generator, package name, version, release number, path of control file"
		    exit 1
	fi

	version=$3
	release=$4
	pkg_path=$1
	pkg_name=$2
	control_path=$5

	cp ${control_path}/${pkg_name}.control ${pkg_path}/${pkg_name}_${version}-${release}_amd64/DEBIAN/control
	sed -i "s/\*\*VERSION\*\*/${version}/g" ${pkg_path}/${pkg_name}_${version}-${release}_amd64/DEBIAN/control
	sed -i "s/\*\*RELEASE\*\*/${release}/g" ${pkg_path}/${pkg_name}_${version}-${release}_amd64/DEBIAN/control

}
