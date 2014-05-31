Name:       hash-signer
Summary:    TBD
Version:    0.0.2
Release:    2
Group:      TO_BE/FILLED_IN
License:    Apache-2.0

Source0:    %{name}-%{version}.tar.gz

%if "%{_repository}" == "wearable"
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
echo "########################################"
echo "TIZEN_PROFILE_WEARABLE"
echo "########################################"
cp -R modules_wearable/* .

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


%else

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
echo "########################################"
echo "TIZEN_PROFILE_MOBILE"
echo "########################################"
cp -R modules_mobile/* .

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/share/license
cp LICENSE %{buildroot}/usr/share/license/%{name}

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
/usr/share/license/%{name}



%endif
