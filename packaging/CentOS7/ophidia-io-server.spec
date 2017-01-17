Name:         ophidia-io-server
Version:      **VERSION**
Release:      **RELEASE**%{?dist}
Summary:      Ophidia IO Server
 
Group:        Ophidia
License:      GPLv3
URL:	      http://ophidia.cmcc.it
Source0:      https://github.com/OphidiaBigData/ophidia-io-server/
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Prefix:       /usr/local
Requires:     mysql-community-libs >= 5.6.22, ophidia-primitives

%description
Ophidia native IO server module to perform I/O and queries on multidimensional data.

%files
%defattr(-,root,root,-)
%license /usr/local/ophidia/oph-cluster/oph-io-server/share/LICENSE 
%license /usr/local/ophidia/oph-cluster/oph-io-server/share/NOTICE.md
/usr/local/ophidia/oph-cluster/oph-io-server
%dir /usr/local/ophidia/oph-cluster/oph-io-server/data1/log
%dir /usr/local/ophidia/oph-cluster/oph-io-server/data1/var

%post
ln -sf /usr/local/ophidia/oph-cluster/oph-io-server/bin/oph_io_server /usr/sbin/oph_io_server

%postun
if [ "$1" = "0" ]; then
	rm -f /usr/sbin/oph_io_server
fi 
