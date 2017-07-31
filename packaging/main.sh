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

if [ $# -lt 2 ]; then
	echo "The following arguments are required: buildtype (master, devel, etc.), distro (centos7, ubuntu14)"
	echo "The following arguments is optional: package (terminal, primitives, server, io-server, io-server-debug or analytics-framework)"
	exit 1
fi

buildtype=$1
distro=$2
package=$3
pkg_path=$PWD

#Prepare environment
mkdir -p ${pkg_path}/sources/${buildtype}
mkdir -p /usr/local/ophidia/pkg

case "${distro}" in
    centos7)
		dist='el7.centos'
		spec_path="${pkg_path}/CentOS7"
        ;;         
    ubuntu14)
		dist='debian'
		spec_path="${pkg_path}/Ubuntu14"
        ;;         
    *)
        echo "Distro can be centos7 or ubuntu14"
        exit 1
esac

PACKAGES=("terminal" "primitives" "io-server" "analytics-framework" "server" "io-server-debug")

if [ ${dist} = 'el7.centos' ]; then
	# For centos linux setup rpmbuild paths
	mkdir -p ${pkg_path}/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}	

	function run_packaging_script_centos {

		if [ $# -ne 1 ]; then
				echo "Package name missing"
				exit 1
		fi

		if [ "${1}" = "io-server" ]; then
			${pkg_path}/scripts/ophidia-${1}-rpm.sh ${buildtype} ${dist} ${pkg_path} ${spec_path} "yes"; if [[ $? != 0 ]]; then exit $?; fi
		else
			${pkg_path}/scripts/ophidia-${1}-rpm.sh ${buildtype} ${dist} ${pkg_path} ${spec_path}; if [[ $? != 0 ]]; then exit $?; fi
		fi
	}

	#Build RPMS
	if [ "${package}" = "terminal" ] || [ "${package}" = "analytics-framework" ] || [ "${package}" = "primitives" ] || [ "${package}" = "server" ] || [ "${package}" = "io-server" ] || [ "${package}" = "io-server-debug" ]; then
		run_packaging_script_centos "${package}"
	elif [ $# -eq 2 ]; then
		for p in ${PACKAGES[@]}; do
			run_packaging_script_centos "${p}"
		done
	fi

	#Move new RPMS
	mv ${pkg_path}/rpmbuild/RPMS/x86_64/*.rpm /usr/local/ophidia/pkg
	rm -rf ${pkg_path}/rpmbuild

elif [ ${dist} = 'debian' ]; then
	mkdir -p ${pkg_path}/debbuild	

	function run_packaging_script_debian {

		if [ $# -ne 1 ]; then
				echo "Package name missing"
				exit 1
		fi

		if [ "${1}" = "io-server" ]; then
			${pkg_path}/scripts/ophidia-${1}-deb.sh ${buildtype} ${pkg_path} ${spec_path} "yes"; if [[ $? != 0 ]]; then exit $?; fi
		else
			${pkg_path}/scripts/ophidia-${1}-deb.sh ${buildtype} ${pkg_path} ${spec_path}; if [[ $? != 0 ]]; then exit $?; fi
		fi
	}

	#Build DEBS
	if [ "${package}" = "terminal" ] || [ "${package}" = "analytics-framework" ] || [ "${package}" = "primitives" ] || [ "${package}" = "server" ] || [ "${package}" = "io-server" ] || [ "${package}" = "io-server-debug" ]; then
		run_packaging_script_debian "${package}"
	elif [ $# -eq 2 ]; then
		for p in ${PACKAGES[@]}; do
			run_packaging_script_debian "${p}"
		done
	fi

	#Move new DEBS
	mv ${pkg_path}/debbuild/*.deb /usr/local/ophidia/pkg
	rm -rf ${pkg_path}/debbuild
fi

#Remove any remaining file
rm -rf ${pkg_path}/sources
rm -rf /usr/local/ophidia/{oph-cluster,oph-server,oph-terminal}
rm -rf /var/www/html/ophidia/*

