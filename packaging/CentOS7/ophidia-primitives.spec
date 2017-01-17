Name:         ophidia-primitives
Version:      **VERSION**
Release:      **RELEASE**%{?dist}
Summary:      Ophidia Primitives

Group:        Ophidia
License:      GPLv3
URL:	      http://ophidia.cmcc.it
Source0:      https://github.com/OphidiaBigData/ophidia-primitives/
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Prefix:       /usr/local
Requires:     zlib, gsl >= 1.13
AutoReqProv:  no

%description
Ophidia libraries implementing array-based primitives to be plugged into IO servers. 

%files
%defattr(-,root,root,-)
%license /usr/local/ophidia/oph-cluster/oph-primitives/share/LICENSE 
%license /usr/local/ophidia/oph-cluster/oph-primitives/share/NOTICE.md
/usr/local/ophidia/oph-cluster/oph-primitives/etc
/usr/local/ophidia/oph-cluster/oph-primitives/lib
