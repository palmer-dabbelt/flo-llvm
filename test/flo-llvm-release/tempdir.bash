set -ex

tempdir=`mktemp -d -t ptest-flo-llvm-c++.XXXXXXXXXX`
trap "rm -rf $tempdir" EXIT
cd $tempdir
