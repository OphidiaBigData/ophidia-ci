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

if [ $# -ne 2 ]
then
        echo "The following arguments are required: buildtype (master, devel, etc.), workspace (where there are the sources)"
        exit 1
fi

buildtype=$1
WORKSPACE=$2

# codestyle check for Ophidia Server

cd $WORKSPACE
git checkout ${buildtype}

find src/ -name 'debug.h' -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200
find src/ -name 'debug.c' -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200
find src/ -name 'oph_*.h' -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200
find src/ -name 'oph_*.c' -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200
find test/ -name 'oph_*.c' -type f -print0 | xargs -0 indent -kr -cli8 -i8 -l200

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

