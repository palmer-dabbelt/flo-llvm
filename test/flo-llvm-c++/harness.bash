set -e
set -x

if [[ "$TEST" == "" ]]
then
    TEST="test"
fi

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
if test -f $TEST.scala
then
    cat $TEST.scala

    scalac $TEST.scala -classpath chisel.jar:.

    scala -classpath chisel.jar:. $TEST \
        --debug --backend flo \
        || true

    touch $TEST.stdin
    while [[ "$(tail -n1 $TEST.stdin)" != "quit" ]]
    do
        scala -classpath chisel.jar:. $TEST \
            --debug --genHarness --compile --test --backend c \
            --vcd --dumpTestInput
    done

    mv $TEST.vcd gold.vcd
    mv $TEST-emulator.cpp harness.c++
    cat $TEST.flo
    mv $TEST.h $TEST-chisel.h
fi

cat $TEST.flo

# Builds the rest of the C++ emulator, which contains a main() that
# actually runs the code.
time $PTEST_BINARY $TEST.flo --header > $TEST.h
cat $TEST.h

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY $TEST.flo --header >$TEST-vg.h 2>vg-$TEST.h
    cat vg-$TEST.h
    if [[ "$(cat vg-$TEST.h | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi

time $PTEST_BINARY $TEST.flo --compat > compat.c++
cat compat.c++

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY $TEST.flo --compat >compat-vg.c++ 2>vg-compat.c++
    cat vg-compat.c++
    if [[ "$(cat vg-compat.c++ | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi

time $clang -g -c -std=c++11 harness.c++ -o harness.llvm -S -emit-llvm
#cat harness.llvm

time $clang -g -c -include $TEST.h -std=c++11 compat.c++ \
    -o compat.llvm -S -emit-llvm
#cat compat.llvm

# Preforms the Flo->LLVM conversion to generate the actual clock
# lines.
time $PTEST_BINARY $TEST.flo --ir > $TEST.llvm
cat $TEST.llvm

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY $TEST.flo --ir >$TEST-vg.llvm 2>vg-$TEST.llvm
    cat vg-$TEST.llvm
    if [[ "$(cat vg-$TEST.llvm | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi

# Links together all the bitcode files
time $llvm_link $TEST.llvm compat.llvm harness.llvm -S > exe.llvm
#cat exe.llvm

# Optimizes the assembly that was generated.  I'm not sure if this is
# necessary to do before I stick in inside the JIT or not...
time $opt -O2 exe.llvm -S > opt.llvm
#cat opt.llvm

# Runs the new emulator inside the LLVM interpreter (or probably JIT
# compiler, if you're using a sane architecture).
$llc opt.llvm -o opt.S
c++ -g opt.S -o opt
if test -f $TEST.stdin
then
    cp $TEST.stdin $TEST.stdin.copy
    cat $TEST.stdin.copy
    time cat $TEST.stdin.copy | ./opt

    if [[ "$have_valgrind" == "true" ]]
    then
        cat $TEST.stdin.copy | valgrind -q ./opt 2>vg-opt
        cat vg-opt
        if [[ "$(cat vg-opt | wc -l)" != "0" ]]
        then
            exit 1
        fi
    fi
else
    time ./opt --vcd $TEST.vcd --cycles 100

    valgrind -q ./opt --vcd $TEST.vcd --cycles 100 2>vg-opt
    cat vg-opt
    if [[ "$(cat vg-opt | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi
cat $TEST.vcd

# Ensures that the two VCD files are actually the same.  Note that
# this allows extra signals to exist in the test file, but at least
# every signal from the gold file must exist.
time vcddiff gold.vcd $TEST.vcd
