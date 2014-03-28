set -e
set -x

source /etc/lsb-release || true

llvm_link="llvm-link"
opt="opt"
llc="llc"
clang="clang"

# For some crazy reason, Ubuntu has decided to have a clang that's
# actually incompatible with their installed LLVM tools.  I don't know
# why anyone would do such a thing... :(.  To avoid all this I just
# have the Ubuntu package explicitly depend on the 3.3 version of the
# tools and postfix all names.
if [[ "$DISTRIB_DESCRIPTION" == "Ubuntu 12.04.4 LTS" ]]
then
    llvm_link="llvm-link-3.3"
    opt="opt-3.3"
    llc="llc-3.3"
    clang="clang" # That's right, the clang-3.3 package installs clang!
fi

have_valgrind="true"
if [[ "$(which valgrind)" == "" ]]
then
    have_valgrind="false"
fi

# Checks if we've been given a scala file, which means everything can
# be generated right from here.
if test -f test.scala
then
    cat test.scala

    scalac test.scala -classpath chisel.jar:.

    scala -classpath chisel.jar:. test \
        --debug --backend flo \
        || true

    touch test.stdin
    while [[ "$(tail -n1 test.stdin)" != "quit" ]]
    do
        scala -classpath chisel.jar:. test \
            --debug --genHarness --compile --test --backend c \
            --vcd --dumpTestInput
    done

    cp -L test.vcd gold.vcd
    cp -L test-emulator.cpp harness.c++
    cat test.flo
    cp -L test.h test-chisel.h
fi

cat test.flo

# Builds the rest of the C++ emulator, which contains a main() that
# actually runs the code.
time $PTEST_BINARY test.flo --header > test.h
cat test.h

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY test.flo --header >test-vg.h 2>vg-test.h
    cat vg-test.h
    if [[ "$(cat vg-test.h | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi

time $PTEST_BINARY test.flo --compat > compat.c++
cat compat.c++

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY test.flo --compat >compat-vg.c++ 2>vg-compat.c++
    cat vg-compat.c++
    if [[ "$(cat vg-compat.c++ | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi

time $clang -g -c -std=c++11 harness.c++ -o harness.llvm -S -emit-llvm
#cat harness.llvm

time $clang -g -c -include test.h -std=c++11 compat.c++ \
    -o compat.llvm -S -emit-llvm
#cat compat.llvm

# Preforms the Flo->LLVM conversion to generate the actual clock
# lines.
time $PTEST_BINARY test.flo --ir > test.llvm
cat test.llvm

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY test.flo --ir >test-vg.llvm 2>vg-test.llvm
    cat vg-test.llvm
    if [[ "$(cat vg-test.llvm | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi

# Links together all the bitcode files
time $llvm_link test.llvm compat.llvm harness.llvm -S > exe.llvm
#cat exe.llvm

# Optimizes the assembly that was generated.  I'm not sure if this is
# necessary to do before I stick in inside the JIT or not...
time $opt -O2 exe.llvm -S > opt.llvm
#cat opt.llvm

# Runs the new emulator inside the LLVM interpreter (or probably JIT
# compiler, if you're using a sane architecture).
$llc opt.llvm -o opt.S
c++ -g opt.S -o opt
if test -f test.stdin
then
    cp test.stdin test.stdin.copy
    cat test.stdin.copy
    time cat test.stdin.copy | ./opt

    if [[ "$have_valgrind" == "true" ]]
    then
        cat test.stdin.copy | valgrind -q ./opt 2>vg-opt
        cat vg-opt
        if [[ "$(cat vg-opt | wc -l)" != "0" ]]
        then
            exit 1
        fi
    fi
else
    time ./opt --vcd test.vcd --cycles 100

    valgrind -q ./opt --vcd test.vcd --cycles 100 2>vg-opt
    cat vg-opt
    if [[ "$(cat vg-opt | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi
cat test.vcd

# Ensures that the two VCD files are actually the same.  Note that
# this allows extra signals to exist in the test file, but at least
# every signal from the gold file must exist.
time vcddiff gold.vcd test.vcd
