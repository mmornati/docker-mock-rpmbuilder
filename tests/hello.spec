Name:           hello
Version:        2.10
Release:        1%{?dist}
Summary:        The "Hello World" program from GNU
License:        GPLv3+
URL:            http://ftp.gnu.org/gnu/hello
Source0:        https://ftp.gnu.org/gnu/hello/hello-%{version}.tar.gz

BuildRequires:  gettext, autoconf, automake, libtool, make, gcc
Requires(post): info
Requires(preun): info

%description
The "Hello World" program from GNU.

%prep
%autosetup

%build
%configure
%make_build

%install
rm -rf %{buildroot}
%make_install

%files
%{_bindir}/hello
%{_mandir}/man1/hello.1*
%doc COPYING
%{_infodir}/hello.info*
%dir %attr(-, root, root) %{_datadir}/locale
%{_datadir}/locale/*/LC_MESSAGES/hello.mo
%exclude %{_infodir}/dir

%post
if [ -L %{_infodir}/hello.info ]
then
  install-info %{_infodir}/hello.info %{_infodir}/dir 2>/dev/null || :
fi

%preun
if [ $1 = 0 ]
then
  install-info --delete %{_infodir}/hello.info %{_infodir}/dir 2>/dev/null || :
fi

%changelog
* Sun May 10 2026 Test User <test@example.com> - 2.10-1
- Initial package for CI testing
