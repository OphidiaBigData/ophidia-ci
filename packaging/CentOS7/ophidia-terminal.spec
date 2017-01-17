Name:         ophidia-terminal  
Version:      **VERSION**
Release:      **RELEASE**%{?dist}
Summary:      Ophidia Terminal
 
Group:        Ophidia
License:      GPLv3
URL:	      http://ophidia.cmcc.it
Source0:      https://github.com/OphidiaBigData/ophidia-terminal/
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Prefix:       /usr/local
Requires:     epel-release, jansson >= 2.4, graphviz >= 2.26.0, gtk2 >= 2.24.23, libxml2 >= 2.7, libcurl >= 7.19, openssl >= 1.0.1e, readline >= 6.0
Requires(post): /bin/sh
Requires(postun): /bin/sh
 
%description
Ophidia terminal, an advanced CLI to send requests and workflows to the Ophidia server.
 
%files
%defattr(-,ophidia,ophidia,-)
%license /usr/local/ophidia/oph-terminal/share/LICENSE 
%license /usr/local/ophidia/oph-terminal/share/NOTICE.md
/usr/local/ophidia/oph-terminal/bin/oph_term

%post
ln -sf /usr/local/ophidia/oph-terminal/bin/oph_term /usr/bin/oph_term
 
%postun
if [ "$1" = "0" ]; then
       rm -f /usr/bin/oph_term
fi
