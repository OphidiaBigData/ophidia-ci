FROM indigodatacloud/packaging:bcentos_latest
MAINTAINER <ophidia-info@cmcc.it>

USER root

RUN yum -y update
RUN yum -y install epel-release
RUN yum -y install http://repo.mysql.com/mysql57-community-release-el7.rpm
    
RUN yum -y groupinstall 'development tools'

RUN yum -y install \
    curl \
    flex-devel \
    git \
    compat-guile18 \
    compat-guile18-devel \
    guile-devel \
    graphviz\* \
    gsl-devel \
    gsl \
    gtk2\* \
    jansson\* \
    libcurl-devel \
    libssh2-devel \
    libtool-ltdl\* \
    libxml2\* \
    mpich\* \
    mysql-community-devel \
    openssl \
    openssl-devel \
    policycoreutils-python \
    readline\* \
    sudo \
    wget \
    indent \
    lcov \
	python-pip \
    cloc \
    netcdf-devel \
    netcdf-mpich-devel \
    hdf5-mpich-devel \
    cfitsio-devel \
    valgrind

RUN pip install \
    gcovr \
    autopep8 \
    flake \
    black

RUN yum -y install \
	httpd \
	php \
	mysql-community-server \
	munge \
	munge-devel \
	munge-libs

RUN yum -y remove mpich-3.2-autoload

USER jenkins

ENV CC /usr/lib64/mpich/bin/mpicc
ENV CPPFLAGS "-I/usr/include/mpich-x86_64/"
ENV LDFLAGS "-L/usr/lib64/mpich/lib/" 
ENV LIB -ldl

RUN sudo mkdir -p /var/run/munge && \
	sudo /bin/bash -c "dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key" && \
	sudo chown -R munge:munge /var/run/munge && \
	sudo chown -R munge:munge /etc/munge && \
	sudo chmod 0711 /var/log/munge && \ 
	sudo chmod 0755 /var/run/munge && \
	sudo chmod 0400 /etc/munge/munge.key

RUN sudo mkdir -p /usr/local/ophidia/extra/src && \
    sudo mkdir -p /var/www/html/ophidia && \
    sudo chown -R jenkins:jenkins /usr/local/ophidia && \
    sudo chown -R jenkins:jenkins /var/www/html/ophidia

RUN cd /usr/local/ophidia/extra/src && \
    wget http://ftp.gnu.org/gnu/libmatheval/libmatheval-1.1.11.tar.gz && \
    wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.0.tar.gz && \
    wget https://sourceforge.net/projects/gsoap2/files/gsoap-2.8/gsoap_2.8.76.zip/download && \
    mv download gsoap_2.8.76.zip && \
    wget https://github.com/SchedMD/slurm/archive/master.tar.gz && \
    wget https://github.com/cisco/cjose/archive/0.4.1.tar.gz && \
    tar zxvf libmatheval-1.1.11.tar.gz && \
    tar zxvf netcdf-4.4.0.tar.gz && \
    unzip gsoap_2.8.76.zip && \
	tar zxvf master.tar.gz && \
    tar -xzf 0.4.1.tar.gz 

RUN cd /usr/local/ophidia/extra/src/libmatheval-1.1.11 && \
    ./configure --prefix=/usr/local/ophidia/extra  && \
    make -s > /dev/null && \
    make install > /dev/null && \
    cd /usr/local/ophidia/extra/src/netcdf-4.4.0 && \
    ./configure \
        --prefix=/usr/local/ophidia/extra \
        --enable-parallel-tests && \
    make -s > /dev/null && \
    make install > /dev/null && \
    cd /usr/local/ophidia/extra/src/gsoap-2.8 && \
    ./configure \
        --prefix=/usr/local/ophidia/extra && \
    make -s > /dev/null && \
    make install > /dev/null && \
	cd /usr/local/ophidia/extra/src/slurm-master && \
	./configure \
		--prefix=/usr/local/ophidia/extra/ \
		--sysconfdir=/usr/local/ophidia/extra/etc/ && \
	make -s > /dev/null && \
	make install > /dev/null && \
	cd /usr/local/ophidia/extra/src/cjose-0.4.1 && \
    ./configure \
        --prefix=/usr/local/ophidia/extra && \
    make -s > /dev/null && \
    make install > /dev/null

RUN mkdir -p /usr/local/ophidia/extra/etc
COPY slurm.conf /usr/local/ophidia/extra/etc/slurm.conf

RUN rm -rf /usr/local/ophidia/extra/src

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/local/ophidia/extra/bin:$PATH
ENV PKG_CONFIG_PATH "/usr/lib64/mpich/lib/pkgconfig/:$PKG_CONFIG_PATH"

RUN sudo sh -c "echo nameserver 8.8.8.8 > /etc/resolv.conf"

RUN sudo mysqld --initialize
 
USER root

EXPOSE 22 

CMD ["/usr/sbin/sshd", "-D"]
