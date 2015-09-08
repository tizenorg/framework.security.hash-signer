Name:       hash-signer
Summary:    TBD
Version:    0.0.1
Release:    2
Group:      TO_BE/FILLED_IN
License:    Apache-2.0
Source0:    %{name}-%{version}.tar.gz
BuildRequires: xmlsec1
Requires:   xmlstarlet
Requires:   xmlsec1
Requires:   zip
Requires:   unzip
%description
TBD

%prep
%setup -q

%build


%install
rm -rf %{buildroot}

mkdir -p %{buildroot}/opt/usr/share/certs/signer
cp -arf certificates/* %{buildroot}/opt/usr/share/certs/signer/
mkdir -p %{buildroot}/usr/bin
cp -arf tools/* %{buildroot}/usr/bin/
mkdir -p %{buildroot}/etc/rpm
cp -arf macros/* %{buildroot}/etc/rpm/

%files
%defattr(-,root,root,-)
/opt/usr/share/certs/signer/*
/usr/bin/*
/etc/rpm/*
