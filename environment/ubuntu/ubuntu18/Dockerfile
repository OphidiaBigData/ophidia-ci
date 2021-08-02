FROM evarga/jenkins-slave
MAINTAINER <ophidia-info@cmcc.it>

USER root

RUN apt-get autoclean
RUN apt-get update

RUN apt-get -y install \
	sudo \
    dpkg-dev \
    debhelper \
    python3 \
    lsb-release

RUN sed -i '/Defaults *requiretty/s/^/#/' /etc/sudoers
RUN sed -i '/root\tALL=/a jenkins ALL=(ALL) NOPASSWD: ALL' /etc/sudoers

RUN apt-get install -y \
	git \
    wget \
	libxml2 \
	libxml2-dev \
	libjansson-dev \
	graphviz-dev \
	libssh2-1-dev \
	libreadline-dev \
    libreadline7 \
	libgtk2.0-dev \
	libgsl-dev \
	libgsl23 \
	gsl-bin \
	libltdl-dev \
	mpich \
	libmpich-dev \
	guile-2.0-dev \
	libfl-dev \
	flex \
	autotools-dev \
	autoconf \
    gcc \
    make \
	indent \
	lcov \
	libbison-dev \
	flex \
	pkg-config \
    unzip \
    valgrind

RUN apt-get install -y \
	libssl-dev \
	libssl1.1 \
	libcurl4 \
	libcurl4-openssl-dev \
	curl

RUN apt-get install -y \
	openssl \
	python-pip \
    cloc \
    libcfitsio-dev \ 
    libhdf5-mpich-dev \
    libhdf5-dev \
    libmatheval-dev \
    libmatheval1

RUN pip install \
    gcovr \
    autopep8 \
    black \
    flake

RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb

RUN export DEBIAN_FRONTEND="noninteractive" && \
	echo 'mysql-apt-config mysql-apt-config/select-server select mysql-5.7' | debconf-set-selections && \
    dpkg -i mysql-apt-config_0.8.11-1_all.deb && \
    rm mysql-apt-config_0.8.11-1_all.deb && \
    apt-get update

RUN export DEBIAN_FRONTEND="noninteractive" && \
	apt-get install -y tzdata && \
    echo "Europe/Rome" > /etc/timezone && \
	dpkg-reconfigure -f noninteractive tzdata


RUN export DEBIAN_FRONTEND="noninteractive" && \
	echo "mysql-server mysql-server/root_password password " | debconf-set-selections && \
	echo "mysql-server mysql-server/root_password_again password " | debconf-set-selections && \
	apt-get install -y mysql-community-server

RUN apt-get install -y \
	libmysqlclient-dev \
	mysql-community-client \
	apache2-bin \
	php \
	libapache2-mod-php \
	munge \
	libmunge-dev \
	libmunge2
	
USER jenkins

ENV CC /usr/bin/mpicc
ENV CPPFLAGS "-I/usr/include/hdf5/mpich/"
ENV LDFLAGS "-L/usr/lib/x86_64-linux-gnu/hdf5/mpich/"
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

RUN cd /usr/local/ophidia/extra/src/netcdf-4.4.0 && \
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

USER root

EXPOSE 22 

CMD ["/usr/sbin/sshd", "-D"]
