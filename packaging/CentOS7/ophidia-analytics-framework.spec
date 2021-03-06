%if 0%{?rhel} == 7
 %define dist .el7.centos
%endif

Name:         ophidia-analytics-framework
Version:      **VERSION**
Release:      **RELEASE**%{?dist}
Summary:      Ophidia Analytics Framework
 
Group:        Ophidia
License:      GPLv3
URL:	      http://ophidia.cmcc.it
Source0:      https://github.com/OphidiaBigData/ophidia-analytics-framework/
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Prefix:       /usr/local
Requires:     mpich, mpich-autoload, mysql-community-libs >= 5.6.22, epel-release, jansson >= 2.4, libxml2 >= 2.7, libcurl >= 7.23, openssl >= 1.0.1e, netcdf >= 4.3.3, netcdf-mpich >= 4.3.3, ophidia-io-server, cfitsio-devel, gsl >= 1.13

%description
Ophidia framework module with all analytics operators. Parallel NetCDF support enabled.

%files
%defattr(-,root,root,-)
%license /usr/local/ophidia/oph-cluster/oph-analytics-framework/share/LICENSE 
%license /usr/local/ophidia/oph-cluster/oph-analytics-framework/share/NOTICE.md
/usr/local/ophidia/oph-cluster/oph-analytics-framework/bin
/usr/local/ophidia/oph-cluster/oph-analytics-framework/etc
/usr/local/ophidia/oph-cluster/oph-analytics-framework/log
/usr/local/ophidia/oph-cluster/oph-analytics-framework/lib
%config(noreplace) /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration
%config(noreplace) /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_soap_configuration
%config(noreplace) /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_script_configuration
/var/www/html/ophidia/operators_xml
/var/www/html/ophidia/img
