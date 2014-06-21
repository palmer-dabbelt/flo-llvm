set -e
set -x

if [[ "$TEST" == "" ]]
then
    TEST="test"
fi

SCALA_FLAGS="-J-Xms512m -J-Xmx900m -J-Xss8m"

source /etc/lsb-release || true

llvm_link="llvm-link"
opt="opt"
llc="llc"
clang="clang"

if [[ "$(basename $PTEST_BINARY)" == "flo-llvm-vcdtmp" ]]
then
    if [[ "$LARGE" == "true" ]]
    then
        exit 0
    fi
fi

for arch in "$(echo $FAILING_ARCHES)"
do
    if [[ "$arch" == "$(uname -m)" ]]
    then
        exit 0
    fi
done

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
elif test -f /etc/debian_version
then
    # Debian still has old versions of everything...
    llvm_link="llvm-link-3.5"
    opt="opt-3.5"
    llc="llc-3.5"
    clang="clang" # That's right, the clang-3.5 package installs clang!
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

    scalac *.scala -classpath chisel.jar:.

    scala $SCALA_FLAGS -classpath chisel.jar:. $TEST $ARGS \
        --debug --backend flo \
        || true

    exargs=""
    if [[ "$(basename $PTEST_BINARY)" == "flo-llvm-vcdtmp" ]]
    then
        exargs="--emitTempNodes"
    elif [[ "$(basename $PTEST_BINARY)" == "flo-llvm-debug" ]]
    then
        exargs="--debug"
    elif [[ "$(basename $PTEST_BINARY)" == "flo-llvm-release" ]]
    then
        exargs=""
    elif [[ "$(basename $PTEST_BINARY)" == "flo-llvm-torture" ]]
    then
        exargs=""
    else
        echo "Pick a run mode!"
        exit 1
    fi

    scala $SCALA_FLAGS -classpath chisel.jar:. $TEST $ARGS \
        --genHarness --dumpTestInput --compile --test --backend c \
        --vcd --testerSeed 0 $exargs

    cat $TEST.stdin
    mv $TEST.vcd gold.vcd
    mv $TEST-emulator.cpp harness.c++
    cat $TEST.flo
    mv $TEST.h $TEST-chisel.h
fi

cat $TEST.flo

if [[ "$STEP_BROKEN" != "true" ]]
then
    cat gold.vcd
    vcd2step gold.vcd $TEST.flo $TEST.stdin
    cat $TEST.stdin
fi

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

time $PTEST_BINARY $TEST.flo --harness > harness.c++
cat harness.c++

if [[ "$have_valgrind" == "true" ]]
then
    valgrind -q $PTEST_BINARY $TEST.flo --harness >harness-vg.c++ 2>vg-harness.c++
    cat vg-harness.c++
    if [[ "$(cat vg-harness.c++ | wc -l)" != "0" ]]
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
$llc -O2 opt.llvm -o opt.S
c++ -g opt.S -o opt
if test -f $TEST.stdin
then
    cp $TEST.stdin $TEST.stdin.copy
    cat $TEST.stdin.copy
    time cat $TEST.stdin.copy | ./opt

    if [[ "$have_valgrind" == "true" ]]
    then
        cp $TEST.vcd $TEST-novg.vcd
        cat $TEST.stdin.copy | valgrind -q ./opt 2>vg-opt
        cat vg-opt
        if [[ "$(cat vg-opt | wc -l)" != "0" ]]
        then
            exit 1
        fi
    fi
else
    time ./opt --vcd $TEST.vcd --cycles 100

    cp $TEST.vcd $TEST-novg.vcd
    valgrind -q ./opt --vcd $TEST.vcd --cycles 100 2>vg-opt
    cat vg-opt
    if [[ "$(cat vg-opt | wc -l)" != "0" ]]
    then
        exit 1
    fi
fi
cat $TEST.vcd

if [[ "$have_valgrind" == "true" ]]
then
    if [[ "$(diff $TEST.vcd $TEST-novg.vcd | wc -l)" != "0" ]]
    then
        diff $TEST.vcd $TEST-novg.vcd
        exit 1
    fi
fi

# Ensures that the two VCD files are actually the same.  Note that
# this allows extra signals to exist in the test file, but at least
# every signal from the gold file must exist.
time vcddiff gold.vcd $TEST.vcd
