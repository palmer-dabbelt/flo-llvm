input="$1"

if [[ "$input" == "" ]]
then
    input="--help"
fi

if [[ "$input" == "--help" ]]
then
    echo "$0 <DESIGN.flo>: Converts Flo files to LLVM IR"
    echo "    The output will be DESIGN.h and DESIGN.o"
    exit 0
fi

tempdir=`mktemp -d -t flo-llvm-wrapper.XXXXXXXXXX`
trap "rm -rf $tempdir" EXIT

flo-llvm-c++ "$input" --header > $tempdir/design.h
flo-llvm-c++ "$input" --compat > $tempdir/compat.c++
flo-llvm-c++ "$input" --ir     > $tempdir/design.llvm

clang -c -S -emit-llvm \
    -I "$(dirname $input)" \
    -include $tempdir/design.h \
    $tempdir/compat.c++ -o $tempdir/compat.llvm

llvm-link $tempdir/design.llvm $tempdir/compat.llvm > $tempdir/link.llvm

llc -O2 $tempdir/link.llvm -o $tempdir/opt.S

c++ $tempdir/opt.S -c -o $tempdir/opt.o

mv $tempdir/opt.o "$(dirname $input)"/"$(basename $input .flo)".o
mv $tempdir/design.h "$(dirname $input)"/"$(basename $input .flo)".h
