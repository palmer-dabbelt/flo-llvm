set -ex

tempdir=`mktemp -d -t ptest-libflo-infer-widths.XXXXXXXXXX`
trap "rm -rf $tempdir" EXIT
cd $tempdir
