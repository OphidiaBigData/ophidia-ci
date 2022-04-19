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

if [ $# -lt 2 ]
then
        echo "The following arguments are required: buildtype (default, master, devel, etc.), workspace (where there are the sources)"
        echo "The following arguments are optional: package (default, terminal, primitives, io-server, server, analytics-framework, PyOphidia or wps-module)"
        exit 1
fi

buildtype=${1}
WORKSPACE=${2}
package=${3}

function check_folder  {
	echo "Check for ${3} in ${2}"
	if [ "${1}" == "c" ]; then
		find ${2} -name ${3} -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200
	else
		eval find ${2} -name ${3} -type f -print0 | xargs -0 black -t py36 --line-length 200
	fi
}



# codestyle check for Ophidia Server

cd $WORKSPACE
if [ "${buildtype}" != "default" ]; then
	git checkout ${buildtype}
fi
if [ "${package}" == "default" ]; then
	IFS='/' tokens=(`pwd`)
	IFS=' '
	folder=${tokens[-1]}
	if [[ $folder == *"primitives"* ]]; then
		package="primitives"
	elif [[ $folder == *"io-server"* ]]; then
		package="io-server"
	elif [[ $folder == *"analytics-framework"* ]]; then
		package="analytics-framework"
	elif [[ $folder == *"server"* ]]; then
		package="server"
	elif [[ $folder == *"terminal"* ]]; then
		package="terminal"
	elif [[ $folder == *"PyOphidia"* ]]; then
		package="PyOphidia"
	elif [[ $folder == *"wps-module"* ]]; then
		package="wps-module"
	else
		echo "Unable to detect package name"
        exit 1
	fi
fi

if [ "${package}" == "primitives" ] || [ $# -lt 3 ]; then

	check_folder "c" src/ 'oph_*.h'
	check_folder "c" src/ 'oph_*.c'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			$(exit 1) 
	fi
fi

if [ "${package}" == "io-server" ] || [ $# -lt 3 ]; then

	check_folder "c" src/client/ 'oph_*.h'
	check_folder "c" src/client/ 'oph_*.c'
	check_folder "c" src/common/ 'debug.h'
	check_folder "c" src/common/ 'debug.c'
	check_folder "c" src/common/ 'oph_*.h'
	check_folder "c" src/common/ 'oph_*.c'
	check_folder "c" src/devices/ '*.h'
	check_folder "c" src/devices/ '*.c'
	check_folder "c" src/iostorage/ 'oph_*.h'
	check_folder "c" src/iostorage/ 'oph_*.c'
	check_folder "c" src/metadb/ 'oph_*.h'
	check_folder "c" src/metadb/ 'oph_*.c'
	check_folder "c" src/network/ 'oph_*.h'
	check_folder "c" src/network/ 'oph_*.c'
	check_folder "c" src/query_engine/ 'oph_query_engine*.h'
	check_folder "c" src/query_engine/ 'oph_query_engine*.c'
	check_folder "c" src/query_engine/ 'oph_query_expression_client.c'
	check_folder "c" src/query_engine/ 'oph_query_expression_evaluator.h'
	check_folder "c" src/query_engine/ 'oph_query_expression_evaluator.c'
	check_folder "c" src/query_engine/ 'oph_query_expression_functions.h'
	check_folder "c" src/query_engine/ 'oph_query_expression_functions.c'
	check_folder "c" src/query_engine/ 'oph_query_plugin*.h'
	check_folder "c" src/query_engine/ 'oph_query_plugin*.c'
	check_folder "c" src/query_engine/ 'oph_query_parser.h'
	check_folder "c" src/query_engine/ 'oph_query_parser.c'
	check_folder "c" src/server/ 'oph_*.h'
	check_folder "c" src/server/ 'oph_*.c'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			git diff
			$(exit 1) 
	fi
fi

if [ "${package}" == "analytics-framework" ] || [ $# -lt 3 ]; then

	check_folder "c" include/ 'debug.h'
	check_folder "c" include/ 'oph_*.h'
	check_folder "c" include/drivers/ '*.h'
	check_folder "c" include/ophidiadb/ '*.h'
	check_folder "c" include/oph_ioserver/ '*.h'
	check_folder "c" include/oph_json/ '*.h'
	check_folder "c" include/query/ '*.h'
	check_folder "c" src/ 'debug.c'
	check_folder "c" src/ 'oph_*.c'
	check_folder "c" src/clients/ '*.c'
	check_folder "c" src/clients/ '*.h'
	check_folder "c" src/drivers/ '*.c'
	check_folder "c" src/ioservers/ '*.c'
	check_folder "c" src/ioservers/ '*.h'
	check_folder "c" src/oph_gsoap/ 'oph_*.h'
	check_folder "c" src/oph_gsoap/ 'oph_*.c'
	check_folder "c" src/ophidiadb/ '*.c'
	check_folder "c" src/oph_ioserver/ '*.c'
	check_folder "c" src/oph_ioserver/ '*.h'
	check_folder "c" src/oph_json/ '*.c'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			$(exit 1) 
	fi
fi

if [ "${package}" == "server" ] || [ $# -lt 3 ]; then

	check_folder "c" src/ 'debug.h'
	check_folder "c" src/ 'debug.c'
	check_folder "c" src/ 'oph_*.h'
	check_folder "c" src/ 'oph_*.c'
	check_folder "c" test/ 'oph_*.c'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			$(exit 1) 
	fi
fi

if [ "${package}" == "terminal" ] || [ $# -lt 3 ]; then

	check_folder "c" src/ 'oph_*.h'
	check_folder "c" src/ 'oph_*.c'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			$(exit 1) 
	fi
fi

if [ "${package}" == "PyOphidia" ] || [ $# -lt 3 ]; then

	check_folder "python" PyOphidia/ '\[^_]*.py'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			$(exit 1) 
	fi
fi

if [ "${package}" == "wps-module" ] || [ $# -lt 3 ]; then

	check_folder "python" processes/ '\[^_]*.py'

	R=$(git status | grep "modified" | wc -l)
	if [ $R -eq 0 ]
		then 
			echo "SUCCESS: all files are compliant with coding style"
			$(exit 0) 
		else 
			echo "WARNING: found $R files not compliant:"
			git status | grep "modified" | sed -n "s/^.*modified:[ ]*//p"
			$(exit 1) 
	fi
fi

