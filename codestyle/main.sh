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

if [ $# -lt 2 ]
then
        echo "The following arguments are required: buildtype (master, devel, etc.), workspace (where there are the sources)"
        echo "The following arguments are optional: package (terminal, primitives, io-server, server or analytics-framework)"
        exit 1
fi

buildtype=$1
WORKSPACE=$2
package=$3

function check_folder {
	find $1 -name $2 -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200
}

# codestyle check for Ophidia Server

cd $WORKSPACE
git checkout ${buildtype}

if [ "${package}" == "primitives" ] || [ $# -lt 3 ]; then

	check_folder src/ 'oph_*.h'
	check_folder src/ 'oph_*.c'

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

	check_folder src/client/ 'oph_*.h'
	check_folder src/client/ 'oph_*.c'
	check_folder src/common/ 'debug.h'
	check_folder src/common/ 'debug.c'
	check_folder src/common/ 'oph_*.h'
	check_folder src/common/ 'oph_*.c'
	check_folder src/devices/ '*.h'
	check_folder src/devices/ '*.c'
	check_folder src/iostorage/ 'oph_*.h'
	check_folder src/iostorage/ 'oph_*.c'
	check_folder src/metadb/ 'oph_*.h'
	check_folder src/metadb/ 'oph_*.c'
	check_folder src/network/ 'oph_*.h'
	check_folder src/network/ 'oph_*.c'
	check_folder src/query_engine/ 'oph_query_engine*.h'
	check_folder src/query_engine/ 'oph_query_engine*.c'
	check_folder src/query_engine/ 'oph_query_expression_client.c'
	check_folder src/query_engine/ 'oph_query_expression_evaluator.h'
	check_folder src/query_engine/ 'oph_query_expression_evaluator.c'
	check_folder src/query_engine/ 'oph_query_expression_functions.h'
	check_folder src/query_engine/ 'oph_query_expression_functions.c'
	check_folder src/query_engine/ 'oph_query_plugin*.h'
	check_folder src/query_engine/ 'oph_query_plugin*.c'
	check_folder src/query_engine/ 'oph_query_parser.h'
	check_folder src/query_engine/ 'oph_query_parser.c'
	check_folder src/server/ 'oph_*.h'
	check_folder src/server/ 'oph_*.c'

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

if [ "${package}" == "analytics-framework" ] || [ $# -lt 3 ]; then

	check_folder include/ 'debug.h'
	check_folder include/ 'oph_*.h'
	check_folder include/drivers/ '*.h'
	check_folder include/ophidiadb/ '*.h'
	check_folder include/oph_ioserver/ '*.h'
	check_folder include/oph_json/ '*.c'
	check_folder include/query/ '*.h'
	check_folder src/ 'debug.c'
	check_folder src/ 'oph_*.c'
	check_folder src/clients/ '*.c'
	check_folder src/clients/ '*.h'
	check_folder src/drivers/ '*.c'
	check_folder src/ioservers/ '*.c'
	check_folder src/ioservers/ '*.h'
	check_folder src/oph_gsoap/ 'oph_*.h'
	check_folder src/ophidiadb/ '*.c'
	check_folder src/oph_ioserver/ '*.c'
	check_folder src/oph_ioserver/ '*.h'
	check_folder src/oph_json/ '*.c'

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

	check_folder src/ 'debug.h'
	check_folder src/ 'debug.c'
	check_folder src/ 'oph_*.h'
	check_folder src/ 'oph_*.c'
	check_folder test/ 'oph_*.c'

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

	check_folder src/ 'oph_*.h'
	check_folder src/ 'oph_*.c'

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

