Name:         ophidia-server 
Version:      **VERSION**
Release:      **RELEASE**%{?dist}
Summary:      Ophidia Server
 
Group:        Ophidia
License:      GPLv3
URL:	      http://ophidia.cmcc.it
Source0:      https://github.com/OphidiaBigData/ophidia-server/
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Prefix:       /usr/local
Requires:     mysql-community-libs >= 5.6.22, libxml2 >= 2.7, libcurl >= 7.19, openssl >= 1.0.1e, libssh2 >= 1.4.2, epel-release, jansson >= 2.4
AutoReqProv:  no

%description
Ophidia server, a service responsible for managing client requests and workflows of Ophidia operators.

%files
%defattr(-,root,root,-)
%license /usr/local/ophidia/oph-server/share/LICENSE 
%license /usr/local/ophidia/oph-server/share/NOTICE.md
/usr/local/ophidia/oph-server
/var/www/html/ophidia/env.php
/var/www/html/ophidia/header.php
/var/www/html/ophidia/index.php
/var/www/html/ophidia/sessions.php
/var/www/html/ophidia/tailer.php
/var/www/html/ophidia/style.css
%dir /var/www/html/ophidia/sessions

%post
ln -sf /usr/local/ophidia/oph-server/bin/oph_server /usr/sbin/oph_server

%postun
if [ "$1" = "0" ]; then
	rm -f /usr/sbin/oph_server
fi 