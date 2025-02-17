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

wait_for_mysql () {
	while [ ! -e /var/lib/mysql/mysql.sock ]; do
		sleep 10
	done
}

set -e

if [ $# -lt 6 ]
then
        echo "The following arguments are required: workspace (where there are the sources), distro (centos7, ubuntu18), base url of pkg repository, file name to be downloaded (without the extension .zip), link to a NC file used for test (with dimensions lat|lon|time), variable to be imported"
        echo "The following arguments are optional: ioserver (mysql ophidiaio), sleeping period (0 by default), number of files to be processed (2 by default), use valgrind (no by default, use \"yes\")"
        exit 1
fi

WORKSPACE=$1
distro=$2
URL=$3
PKG=$4
NCFILE=$5
VARIABLE=$6
IOSERVER=$7
PERIOD=$8
NFILE=$9
USEVALGRIND=$10

pkg_path=$PWD

case "${distro}" in
        centos7)
			dist='el7.centos'
            ;;         
        ubuntu18)
			dist='debian'
            ;;         
        *)
            echo "Distro can be centos7 or ubuntu18"
            exit 1
esac

# Install Ophidia & Services

ssh-keygen -t rsa -f /home/jenkins/.ssh/id_rsa -N ""
cat /home/jenkins/.ssh/id_rsa.pub >> /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/authorized_keys

ssh -o "StrictHostKeyChecking no" 127.0.0.1 ":"

if [ ${URL} != 'NULL' ]
then

	# ophidia-packages download

	mkdir -p /usr/local/ophidia/pkg
	cd /usr/local/ophidia/pkg

	wget --no-check-certificate "${URL}/${PKG}.zip"
	unzip ${PKG}.zip
	cd PKG

	# install packages

	if [ ${dist} = 'el7.centos' ]
	then
		sudo yum -y install ophidia-*.rpm
	fi
	if [ ${dist} = 'debian' ]
	then
		sudo dpkg -i ophidia-*.deb
	fi

fi

# Configuration

if [ ${dist} = 'el7.centos' ]
then
	sudo cp -pr /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib64/mysql/plugin
fi
if [ ${dist} = 'debian' ]
then
	sudo cp -pr /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib/mysql/plugin
fi

sudo chown -R jenkins:jenkins /usr/local/ophidia
sudo chown -R jenkins:jenkins /var/www/html/ophidia

sed -i -- 's/PORT=3306/PORT=3307/g' /usr/local/ophidia/oph-server/etc/ophidiadb.conf
sed -i -- 's/PORT=3306/PORT=3307/g' /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration
if [ ${dist} = 'el7.centos' ]
then
	sed -i -- 's/TO `%`/TO `root`@`localhost`/g' /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql
fi

# Re-install io-server in debug mode

#mkdir -p /usr/local/ophidia/src/test
#cd /usr/local/ophidia/src/test
#git clone https://github.com/OphidiaBigData/ophidia-io-server
#cd /usr/local/ophidia/src/ophidia-io-server
#git checkout devel
#./bootstrap
#./configure --prefix=/usr/local/ophidia/oph-cluster/oph-io-server --disable-mem-check > /dev/null
#echo `make -j2 -s > /dev/null`
#echo "Do not care previous possible errors"
#make -s > /dev/null
#make install -s > /dev/null

# Config Ophidia Server

cp ${pkg_path}/etc/server.conf /usr/local/ophidia/oph-server/etc/

cd /usr/local/ophidia/oph-server/etc/cert/

openssl req -newkey rsa:1024 -passout pass:abcd  -subj "/" -sha1 -keyout rootkey.pem -out rootreq.pem
openssl x509 -req -in rootreq.pem -passin pass:abcd -sha1 -extensions v3_ca -signkey rootkey.pem -out rootcert.pem
cat rootcert.pem rootkey.pem  > cacert.pem

openssl req -newkey rsa:1024 -passout pass:abcd -subj "/" -sha1 -keyout serverkey.pem -out serverreq.pem
openssl x509 -req -in serverreq.pem -passin pass:abcd -sha1 -extensions usr_cert -CA cacert.pem -CAkey cacert.pem -CAcreateserial -out servercert.pem
cat servercert.pem serverkey.pem rootcert.pem > myserver.pem

rm -rf server* root* cacert.srl

# Start services

echo "Start MySQL"
if [ ${dist} = 'el7.centos' ]
then
	echo 'port = 3307' | sudo tee -a /etc/my.cnf > /dev/null
    
	sudo chmod 0444 /etc/my.cnf
	sudo chown jenkins:jenkins /etc/my.cnf
	sudo chown -R jenkins:jenkins /var/lib/mysql
	sudo chmod -R a+w /var/lib/mysql
	sudo chmod a+rw /var/log/mysqld.log
	sudo chown -R jenkins:jenkins /var/run/mysqld/
	sudo chmod -R a+rw /var/run/mysqld/

	rm -f /var/lib/mysql/mysql.sock
	/usr/sbin/mysqld --user=jenkins --skip-grant-tables </dev/null &
	echo "Waiting for MySQL"
	wait_for_mysql
	mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY 'abcd';"

	killall mysqld

	rm -f /var/lib/mysql/mysql.sock
	/usr/sbin/mysqld --user=jenkins </dev/null &
fi
if [ ${dist} = 'debian' ]
then
	echo '[mysqld]' | sudo tee -a /etc/my.cnf > /dev/null
	echo 'port = 3307' | sudo tee -a /etc/my.cnf > /dev/null
	echo '[mysqladmin]' | sudo tee -a /etc/my.cnf > /dev/null
	echo 'port = 3307' | sudo tee -a /etc/my.cnf > /dev/null

	sudo service mysql start
	sudo mysql -u root --batch --silent -e "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; CREATE USER '%'@'%' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO '%'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;";
fi

echo "Start Apache"
if [ ${dist} = 'el7.centos' ]
then
	sudo /usr/sbin/httpd
fi
if [ ${dist} = 'debian' ]
then
	sudo service apache2 start
fi

cp -f ${pkg_path}/etc/slurm.conf /usr/local/ophidia/extra/etc

echo "Start Munge"
if [ ${dist} = 'el7.centos' ]
then
	sudo -u munge /usr/sbin/munged
fi
if [ ${dist} = 'debian' ]
then
	sudo service munge start
fi

sudo /usr/local/ophidia/extra/sbin/slurmd
sudo /usr/local/ophidia/extra/sbin/slurmctld

# Wait for services to start

if [ ${dist} = 'el7.centos' ]
then
	echo "Waiting for MySQL"
	wait_for_mysql
fi

# Config services

echo "Configure MySQL"
if [ ${dist} = 'debian' ]
then
	mysqladmin -u root password 'abcd'
fi
echo "[client]" > /home/jenkins/.my.cnf
echo "password=abcd" >> /home/jenkins/.my.cnf
echo "port=3307" >> /home/jenkins/.my.cnf

mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"
sleep 5

# Load ophidia-primitives

echo "Load primitives"
mysql -u root mysql < /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql

# Load Ophidia DB
partition="main"
echo "Load Ophidia DB"
echo "create database ophidiadb;" | mysql -u root
echo "create database oph_dimensions;" | mysql -u root
mysql -u root ophidiadb < /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/ophidiadb.sql
echo "INSERT INTO host (hostname, cores, memory) VALUES ('127.0.0.1', 1, 1);" | mysql -u root ophidiadb
echo "INSERT INTO hostpartition (partitionname) VALUES ('${partition}');" | mysql -u root ophidiadb
echo "INSERT INTO hashost (idhostpartition,idhost) VALUES (1,1);" | mysql -u root ophidiadb
echo "INSERT INTO dbmsinstance (idhost, login, password, port) VALUES (1, 'root', 'abcd', 3307);" | mysql -u root ophidiadb
echo "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) VALUES (1, 'root', 'abcd', 65000, 'ophidiaio_memory');" | mysql -u root ophidiadb

# Start Ophidia Server

echo "Start Ophidia Server"
sudo ln -s /usr/local/ophidia/extra/bin/srun /bin/srun

if [ "$USEVALGRIND" == "yes" ]
then
	valgrind --leak-check=full /usr/local/ophidia/oph-server/bin/oph_server -d > /usr/local/ophidia/oph-server/log/trace.log 2>&1 < /dev/null &
else
	/usr/local/ophidia/oph-server/bin/oph_server -d > /usr/local/ophidia/oph-server/log/trace.log 2>&1 < /dev/null &
fi

# Start the Ophidia IO Server

echo "Start ophidia I/O Server"
/usr/local/ophidia/oph-cluster/oph-io-server/bin/oph_io_server -i 1 -d > /dev/null 2>&1 < /dev/null &

# Wait for services to start

sleep 10

# Initial tracing

echo "Initial server trace begin"
cat /usr/local/ophidia/oph-server/log/trace.log
echo "Initial server trace end"

# Init environment for tests

TESTN=1

execc () {
	TIME=$(date +%s)
	echo "Test $TESTN: EXEC COMMAND $2"
	$INSTALL/oph_term $ACCESSPARAM -e "$2" > $1$TIME.json 2>&1
	if [ $(grep "ERROR" $1$TIME.json | wc -l) -gt 0 ]; then cat /usr/local/ophidia/oph-server/log/server.log; cat $1$TIME.json; $(exit 1); else $(exit 0); fi
	if [ $(grep "fault" $1$TIME.json | wc -l) -gt 0 ]; then cat /usr/local/ophidia/oph-server/log/server.log; cat $1$TIME.json; $(exit 1); else $(exit 0); fi
	> /usr/local/ophidia/oph-server/log/server.log
	let "TESTN++"
}
execw () {
	TIME=$(date +%s)
	echo "Test $TESTN: EXEC WORKFLOW $2 $3"
	$INSTALL/oph_term $ACCESSPARAM -w "$2" -a "$3" > $1$TIME.json 2>&1
	if [ $(grep "ERROR" $1$TIME.json | wc -l) -gt 0 ]; then cat /usr/local/ophidia/oph-server/log/server.log; cat $1$TIME.json; $(exit 1); else $(exit 0); fi
	if [ $(grep "fault" $1$TIME.json | wc -l) -gt 0 ]; then cat /usr/local/ophidia/oph-server/log/server.log; cat $1$TIME.json; $(exit 1); else $(exit 0); fi
	> /usr/local/ophidia/oph-server/log/server.log
	let "TESTN++"
}

core=1
cwd=/jenkins
INSTALL=/usr/local/ophidia/oph-terminal/bin
ACCESSPARAM="-H 127.0.0.1 -P 11732 -u oph-test -p abcd"


# Use $HOME as working directory
cd


# Server check
echo "Configuration Parameters"
$INSTALL/oph_term $ACCESSPARAM -e "oph_get_config" > server_check$TIME.json
if [ $(grep "Configuration Parameters" server_check$TIME.json | wc -l) -gt 0 ]; then $(exit 0); else $(exit 1); fi



# Sleeping period
if [ $# -gt 7 ]; then
	sleep $PERIOD
fi


# Files to be processed
if [ $# -lt 9 ]; then
	NFILE=2
fi


# Functional tests

echo "Start functional tests"

# Create test folder and test container
execc mk "oph_folder command=mkdir;path=/jenkins;cwd=/;"
execc cc "oph_createcontainer container=jenkins;dim=lat|lon|plev|time;dim_type=double|double|double|double;hierarchy=oph_base|oph_base|oph_base|oph_time;vocabulary=CF;cwd=$cwd;"
execc ls "oph_list cwd=$cwd;"

# Download NC file
echo "Try to download ${NCFILE}"
cd $WORKSPACE
wget --no-check-certificate -O file.nc ${NCFILE} > /dev/null 2>&1
for i in `seq 2 ${NFILE}`; do
	cp -p file.nc file_$i.nc
done

if [ "$IOSERVER" == "mysql" ] || [ $# -lt 7 ]; then
	# Massive import MySQL IO server
	execc imp "oph_importnc src_path=[$WORKSPACE/*.nc];measure=${VARIABLE};imp_concept_level=d;imp_dim=time;container=jenkins;host_partition=$partition;ioserver=mysql_table;ncores=$core;cwd=$cwd;"
fi
if [ "$IOSERVER" == "ophidiaio" ] || [ $# -lt 7 ]; then
	# Massive import Ophidia IO server
	execc imp "oph_importnc src_path=[$WORKSPACE/*.nc];measure=${VARIABLE};imp_concept_level=d;imp_dim=time;container=jenkins;host_partition=$partition;ioserver=ophidiaio_memory;ncores=$core;cwd=$cwd;"
fi
execc csz "oph_cubesize cube=[measure=${VARIABLE}];cwd=$cwd;"
execc ce "oph_cubeelements cube=[measure=${VARIABLE}];cwd=$cwd;"
execc cs "oph_cubeschema cube=[measure=${VARIABLE}];cwd=$cwd;"
echo `execc dc "oph_delete cube=[measure=${VARIABLE}];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=${VARIABLE}];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=${VARIABLE}];ncores=$core;cwd=$cwd;"`

if [ "$IOSERVER" == "mysql" ] || [ $# -lt 7 ]; then
	# Randcube MySQL IO server
	execc rc "oph_randcube compressed=no;container=jenkins;dim=lat|lon|time;dim_size=16|100|360;exp_ndim=2;host_partition=$partition;measure=jenkins;measure_type=float;nfrag=16;ntuple=100;concept_level=c|c|d;ioserver=mysql_table;nhost=1;ncores=$core;cwd=$cwd;"
fi
if [ "$IOSERVER" == "ophidiaio" ] || [ $# -lt 7 ]; then
	# Randcube Ophidia IO server
	execc rc "oph_randcube compressed=no;container=jenkins;dim=lat|lon|time;dim_size=16|10|360;exp_ndim=2;host_partition=$partition;measure=jenkins;measure_type=float;nfrag=16;ntuple=10;concept_level=c|c|d;ioserver=ophidiaio_memory;nhost=1;ncores=$core;cwd=$cwd;"
fi

# Apply operations
execc app "oph_apply query=oph_math(measure,'OPH_MATH_ATAN');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(oph_sum_scalar(measure,1000),'OPH_MATH_ATAN');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_sum_scalar(oph_math(measure,'OPH_MATH_ATAN'),1000);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray(measure,101,200);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator(measure,'OPH_AVG','OPH_ALL');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator(measure,'OPH_SUM','OPH_ALL');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator(measure,'OPH_MAX','OPH_ALL');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_sum_scalar(measure,-12.5);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_mul_scalar(measure,-12.5);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_sum_scalar2(measure,-12.5,4);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_mul_scalar2(measure,-12.5,-3.7);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_sum_array('oph_float|oph_float','oph_double',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_sub_array('oph_float|oph_float','oph_int',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_mul_array('oph_float|oph_float','oph_long',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_div_array('oph_float|oph_float','oph_float',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_abs_array('oph_float|oph_float','oph_int',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_arg_array('oph_float|oph_float','oph_double',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_max_array('oph_float|oph_float','oph_long',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_min_array('oph_float|oph_float','oph_double',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_mask_array('oph_float|oph_float','oph_long',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_int',measure,measure,'OPH_MAX');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_double',measure,measure,'OPH_MIN');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_float',measure,measure,'OPH_SUM');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_int',measure,measure,'OPH_SUB');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_long',measure,measure,'OPH_MUL');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_int',measure,measure,'OPH_DIV');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_long',measure,measure,'OPH_ABS');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_float',measure,measure,'OPH_ARG');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_operator_array('oph_float|oph_float','oph_double',measure,measure,'OPH_MASK');check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_aggregate_operator(measure,'OPH_MAX');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_aggregate_operator(measure,'OPH_MIN');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_aggregate_operator(measure,'OPH_AVG');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_aggregate_operator(measure,'OPH_SUM');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_shift(measure,100,-30);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_shift(measure,-100,30);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_rotate(measure,100);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_rotate(measure,-100);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reverse(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_ABS');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_ATAN');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_CEIL');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_FLOOR');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_COS');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_SIN');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_EXP');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_ROUND');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_TAN');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_math(measure,'OPH_MATH_ABS');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_append(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_append('oph_float|oph_float','oph_float',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_append('oph_float|oph_float|oph_float','oph_float',measure,measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_accumulate(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_deaccumulate(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_extend(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_extend(measure,2);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_extend(measure,3,'i');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_interlace('oph_float|oph_float','oph_float',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_interlace('oph_float|oph_float|oph_float','oph_float',measure,measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
#execc app "oph_apply query=oph_moving_avg(measure,2);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
#execc app "oph_apply query=oph_moving_avg(measure,0.5,'oph_ewma');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_predicate(measure,'x-100','>0','sqrt(x)-100','-x^2');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray2(measure,'2:17');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray2(measure,'1:2:end',36);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray2(measure,'1:2,4',3,4);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray3(measure,'2:17',1,360);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray3(measure,'1:2:end',36,10);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray3(measure,'1:2,4',12,30);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray3(measure,'1:2,4',12,30,'2:7',1,12);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_get_subarray3(measure,'2:7',1,12,'20:end,4',12,30);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_permute(measure,'2,1',12,30);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce(measure,'OPH_MAX',10);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce(measure,'OPH_MIN',20);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce(measure,'OPH_AVG',30);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce(measure,'OPH_STD',40);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce2(measure,'OPH_MAX',10,1,360);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce2(measure,'OPH_MIN',20,2,180);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce2(measure,'OPH_ARG_MAX',10,4,90);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce2(measure,'OPH_ARG_MIN',9,4,90);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce2(measure,'OPH_AVG',12,10,36);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_reduce2(measure,'OPH_STD',5,36,10);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_aggregate_stats(measure,'1111111');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_aggregate_stats_partial(measure,'1111111');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_concat('oph_float|oph_float','oph_float',measure,measure);check_type=no;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_roll_up(measure,10);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
# GSL
execc app "oph_apply query=oph_gsl_sd(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_gsl_boxplot(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_gsl_quantile(measure,0.25);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_gsl_quantile(measure,0.25,0.5,0.75);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_gsl_sort(measure);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc app "oph_apply query=oph_gsl_histogram(measure,10);measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
# Clear
echo `execc dc "oph_delete cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"`

# APEX
if [ "$IOSERVER" == "mysql" ] || [ $# -lt 7 ]; then
	execc rc "oph_randcube compressed=no;container=jenkins;dim=lat|lon|time;dim_size=16|100|360;exp_ndim=2;host_partition=$partition;measure=jenkins;measure_type=float;nfrag=16;ntuple=100;concept_level=c|c|d;ioserver=mysql_table;nhost=1;ncores=$core;cwd=$cwd;"
fi
if [ "$IOSERVER" == "ophidiaio" ] || [ $# -lt 7 ]; then
	execc rc "oph_randcube compressed=no;container=jenkins;dim=lat|lon|time;dim_size=16|10|360;exp_ndim=2;host_partition=$partition;measure=jenkins;measure_type=float;nfrag=16;ntuple=10;concept_level=c|c|d;ioserver=ophidiaio_memory;nhost=1;ncores=$core;cwd=$cwd;"
fi
execc dup "oph_duplicate cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc rdc "oph_duplicate cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"
execc agr "oph_aggregate2 cube=[measure=jenkins;level=2];dim=lon;operation=avg;ncores=$core;cwd=$cwd;"
execc ecb "oph_explorecube cube=[measure=jenkins;level=3];show_id=yes;show_index=yes;subset_dims=lat|time;subset_filter=0:1000|0:200;subset_type=coord;cwd=$cwd;"
execc mrg "oph_merge cube=[measure=jenkins;level=3];nmerge=16;ncores=$core;cwd=$cwd;"
execc agr "oph_aggregate2 cube=[measure=jenkins;level=4];dim=lat;operation=min;ncores=$core;cwd=$cwd;"
execc rdc "oph_reduce2 cube=[measure=jenkins;level=5];dim=time;operation=sum;ncores=$core;cwd=$cwd;"
execc rdc "oph_duplicate cube=[measure=jenkins;level=5];ncores=$core;cwd=$cwd;"
execc ecb "oph_explorecube cube=[measure=jenkins;level=6];cwd=$cwd;"
execc cio "oph_cubeio cube=[measure=jenkins;level=0];cwd=$cwd;"
execc cio "oph_cubeio cube=[measure=jenkins;level=3];cwd=$cwd;"
execc cio "oph_cubeio cube=[measure=jenkins;level=6];cwd=$cwd;"

# Subsetting
echo `execc dc "oph_delete cube=[measure=jenkins;level=2];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=2];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=2];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=3];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=3];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=3];ncores=$core;cwd=$cwd;"`
execc sub2 "oph_subset cube=[measure=jenkins;level=1];subset_dims=lon|time;subset_filter=0:1000|0:500;subset_type=coord;ncores=$core;cwd=$cwd;"
execc cs "oph_cubeschema cube=[measure=jenkins;level=1];cwd=$cwd;"

# Missing values
echo `execc dc "oph_delete cube=[measure=jenkins;level=1|2|3];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins;level=1|2|3];ncores=$core;cwd=$cwd;"`
execc apl "oph_apply query=oph_predicate(measure,'x-800','>0','NAN','x');measure_type=auto;cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc apl "oph_apply query=oph_cast('oph_float','oph_short',measure,NULL,-1000);cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"
execc apl "oph_apply query=oph_cast('oph_float','oph_int',measure,NULL,-1000);cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"
execc apl "oph_apply query=oph_cast('oph_float','oph_long',measure,NULL,-1000);cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"
execc apl "oph_apply query=oph_cast('oph_float','oph_double',measure,NULL,-1000);cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"
execc red "oph_reduce2 operation=min;dim=time;cube=[measure=jenkins;level=2];ncores=$core;cwd=$cwd;"
execc red "oph_reduce2 operation=min;dim=time;missingvalue=-1000;cube=[measure=jenkins;level=2];ncores=$core;cwd=$cwd;"
execc agr "oph_aggregate2 operation=max;dim=lon;cube=[measure=jenkins;level=3];ncores=$core;cwd=$cwd;"
execc agr "oph_aggregate2 operation=max;dim=lon;missingvalue=-1000;cube=[measure=jenkins;level=3];ncores=$core;cwd=$cwd;"

echo `execc dc "oph_delete cube=[measure=jenkins];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins];ncores=$core;cwd=$cwd;"`

# Roll-up & drill-down (only MySQL)
execc rc "oph_randcube container=jenkins;dim=lat|lon|time;dim_size=16|100|360;exp_ndim=2;host_partition=$partition;measure=jenkins;measure_type=float;nfrag=16;ntuple=100;concept_level=c|c|d;ioserver=mysql_table;nhost=1;ncores=$core;cwd=$cwd;"
execc rup "oph_rollup cube=[measure=jenkins;level=0];ncores=$core;cwd=$cwd;"
execc dwn "oph_drilldown cube=[measure=jenkins;level=1];ncores=$core;cwd=$cwd;"
execc cio "oph_cubeio cube=[measure=jenkins;level=2];cwd=$cwd;"

# Flush residual data
echo `execc dc "oph_delete cube=[measure=jenkins];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins];ncores=$core;cwd=$cwd;"`
echo `execc dc "oph_delete cube=[measure=jenkins];ncores=$core;cwd=$cwd;"`

execc dc "oph_deletecontainer container=jenkins;cwd=$cwd;"
execc rmf "oph_folder command=rm;path=jenkins;cwd=/;"
execc ls "oph_list cwd=/;"

# Test file system access
execc lsd "oph_fs command=ls;"
execc cdd "oph_fs command=cd;dpath=$WORKSPACE;"
execc lsd "oph_fs command=ls;"

# Integration test

echo "Start integration tests"

git clone https://github.com/OphidiaBigData/ophidia-workflow-catalogue.git
cd ophidia-workflow-catalogue/indigo/test
git checkout devel

execw wf1 "test1.json" "$core,$WORKSPACE/file.nc,${VARIABLE}"
execw wf2 "test2.json" "$core,$WORKSPACE/file.nc,${VARIABLE}"
execw wf30 "test3.json" "$core,$WORKSPACE/file.nc,${VARIABLE},0"
execw wf31 "test3.json" "$core,$WORKSPACE/file.nc,${VARIABLE},1"
execw wf400 "test4.json" "$core,$WORKSPACE/file.nc,${VARIABLE},0,0"
execw wf401 "test4.json" "$core,$WORKSPACE/file.nc,${VARIABLE},0,1"
execw wf410 "test4.json" "$core,$WORKSPACE/file.nc,${VARIABLE},1,0"
execw wf411 "test4.json" "$core,$WORKSPACE/file.nc,${VARIABLE},1,1"
execw wf50 "test5.json" "$core,$WORKSPACE/file.nc,${VARIABLE},1,no"
execw wf51 "test5.json" "$core,$WORKSPACE/file.nc,${VARIABLE},0,no"
execw wf52 "test5.json" "$core,$WORKSPACE/file.nc,${VARIABLE},0,yes"

echo "Stop integration tests"

# Final tracing

echo "Final server trace begin"
cat /usr/local/ophidia/oph-server/log/trace.log
echo "Final server trace end"

exit 0

