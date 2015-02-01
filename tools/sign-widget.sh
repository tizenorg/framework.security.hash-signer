#!/bin/bash

cleantempfiles()
{
    if test ! -z $template && test -e $template
    then
        rm $template
    fi
    if test ! -z $tempsig && test -e $tempsig
    then
        rm $tempsig
    fi
    if test ! -z $tempsig2 && test -e $tempsig2
    then
        rm $tempsig2
    fi
    if test ! -z $oldtemp && test -e $oldtemp
    then
        rm $oldtemp
    fi
}

function findfiles() {
	exception=""
	if [ $author -eq 1 ]
	then
		exception="-not -name author-signature.xml"
	fi

	echo  $(find . -type f $exception -not -name 'signature*.xml' |  sed -e 's,^\.\/,,' | sed -f /usr/bin/url-encode.sed)
}

. $(dirname $0)/realpath.sh
outname=signature1.xml
identifier=""
author=0
# rsa by default http://www.w3.org/TR/widgets-digsig/#signature-algorithms
KEYTYPE="rsa"

if [ $# -eq 0 ]
then
    echo "Usage $0 [xmlsec options] [options] widget"
    echo "	-o filename	Set signature filename (default: $outname)"
    echo "	-i ID		Set dsp:Identifier value (default: <random>)"
    echo "	-a  Set signature type to author"
    echo "	-d  Set key type to DSA"
    echo "	-u  Update digests and signature (in signature specified by -o), don't regenerate"
    echo "	-c  Specify the X509 certificate"
    echo "	-x  Don't verify after signing"
    echo "	widget may be a directory or .wgt file"
    echo
    echo "You should include the following xmlsec options:"
    echo "	--pkcs12 /absolute/path/to/keycert.p12"
    echo "	--pwd password"
    echo "  --trusted-pem   /absolute/path/to/root.pem"
    echo "  --untrusted-pem /absolute/path/to/second.pem"
    exit 2;
fi

while [[ $1 == --* ]]; do
	XMLSECOPTIONS="$XMLSECOPTIONS $1"
	if [[ $2 != --* ]]
	then
		XMLSECOPTIONS="$XMLSECOPTIONS $2"
		shift 2
	else
		echo Missing argument
		exit 2
	fi
done

certfile=""
validate=1
update=0
while getopts "o:i:aduc:x" o
do
	case "$o" in
	(o) outname=$OPTARG;;
	(i) identifier="--identifier $OPTARG";;
	(a) author=1;;
	(d) KEYTYPE="dsa";;
	(u) update=1;;
	(c) certfiles=`printf "%s\n%s" "$certfiles" "$OPTARG"`;;
	(x) validate=0;;
	(*)  break;;
	esac
done
shift $((OPTIND - 1))

echo Key type $KEYTYPE

if ! test -e "$1"
then
	echo $1 does not exist
	exit 2
fi

temp=$(realpath "$1")
WD=$(dirname "$temp")
BASE=$(dirname $(realpath $0))
WIDGET=$(basename "$1" .wgt)

if [ -d "$1" ]
then
    echo "Package is a directory"
    wgtdir="$1"
else
    wgtdir="/tmp/.$$/$WIDGET"
    echo "Working in $wgtdir"
    mkdir -p $wgtdir
    unzip "$1" -d $wgtdir
fi

cd "$wgtdir"

template=`mktemp /tmp/signature-tmp.XXXXX`
tempsig=`mktemp /tmp/signature-tmp.XXXXX`
tempsig2=`mktemp /tmp/signature-tmp.XXXXX`


if [ $author -eq 1 ]
then
	outname="author-signature.xml"

    if [ $update -eq 0 ]
    then
    	$BASE/signing-template.sh --method $KEYTYPE --role author $identifier $(findfiles) > $template
	else
        template=$outname
    fi
	
	xmlsec1 sign $XMLSECOPTIONS --output $tempsig $template
	ret=$?
    if test "$ret" != "0"
    then
        echo "Failed to generate Author Signature. [$ret]"
        cleantempfiles
        exit $ret
    fi
else
    if [ $update -eq 0 ]
    then
        $BASE/signing-template.sh --method $KEYTYPE --role distributor $identifier $(findfiles) > $template
    else
        template=$outname
    fi
	xmlsec1 sign $XMLSECOPTIONS --output $tempsig $template
	ret=$?
    if test "$ret" != "0"
    then
        echo "Failed to generate Distributor Signature. [$ret]"
        cleantempfiles
        exit $ret
    fi
fi

for file in $certfiles
do
    if [ -n "$file" ]
    then
        echo "Adding certificate $file"
        oldtemp=$tempsig
        tempsig=`mktemp /tmp/tmp.XXXXX`
        # Get the certificate and remove the header/footer
        cert=`openssl x509 -in $file | grep -v -- "-----"`

        xmlstarlet ed -P -N sig=http://www.w3.org/2000/09/xmldsig# -s "//sig:X509Data" -t elem -n "X509Certificate" -v "$cert" $oldtemp > $tempsig
	    ret=$?
        if test "$ret" != "0"
        then
            echo "Failed to generate Author Signature. [$ret]"
            cleantempfiles
            exit $ret
        fi
    fi
done

# cp $tempsig $outname
# Re-order
xmlstarlet ed -P -N s="http://www.w3.org/2000/09/xmldsig#" -m "//s:Signature/s:KeyInfo/s:X509Data/s:X509Certificate[2]" "//s:Signature/s:KeyInfo/s:X509Data" $tempsig > $tempsig2
ret=$?
if test "$ret" != "0"
then
    echo "Failed to generate Distributor Signature. [$ret]"
    cleantempfiles
    exit $ret
fi
xmlstarlet ed -P -N s="http://www.w3.org/2000/09/xmldsig#" -m "//s:Signature/s:KeyInfo/s:X509Data/s:X509Certificate[1]" "//s:Signature/s:KeyInfo/s:X509Data" $tempsig2 > $outname
ret=$?
if test "$ret" != "0"
then
    echo "Failed to generate Distributor Signature. [$ret]"
    cleantempfiles
    exit $ret
fi
chmod 744 $outname


if [ $update -eq 1 ]
then
    echo "Updated $outname"
else
    echo "Signed $outname"
fi

if [ $validate -eq 1 ]
then
    echo -n "Validating... "
    validatecmd="$BASE/validate-widget.sh $XMLSECOPTIONS $PWD"
    $validatecmd 
    if [ "$?" -ne 0 ]
    then
        echo "FAILED with command:"
        echo "$validatecmd"
    else
        echo "SUCCESS"
    fi
    echo
fi

pkgname=$(basename "$1")
cd $WD
if [ -f "$pkgname" ]
then
    echo "Zipping widget..."
    rm -f "$pkgname"
    cd $wgtdir
    zip -r $WD/$WIDGET.wgt ./
    cd $WD
    rm -rf $wgtdir
fi

echo Signed $1

cleantempfiles
