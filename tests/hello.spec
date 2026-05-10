Name:           hello
Version:        2.10
Release:        1%{?dist}
Summary:        The "Hello World" program from GNU
License:        GPLv3+
URL:            http://ftp.gnu.org/gnu/hello
Source0:        https://ftp.gnu.org/gnu/hello/hello-%{version}.tar.gz

BuildRequires:  gettext
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
%make_install

%files
%{_bindir}/hello
%{_mandir}/man1/hello.1*
%doc COPYING

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
