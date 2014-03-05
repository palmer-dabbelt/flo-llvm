set -e
set -x

# Checks if we've been given a scala file, which means everything can
# be generated right from here.
if test -f test.scala
then
    cat test.scala

    scalac test.scala -classpath chisel.jar:.

    scala -classpath chisel.jar:. test \
        --debug --backend flo \
        || true

    scala -classpath chisel.jar:. test \
        --debug --genHarness --compile --test --backend c --vcd

    mv test.vcd gold.vcd
    mv test-emulator.cpp harness.c++
fi

# Builds the rest of the C++ emulator, which contains a main() that
# actually runs the code.
time $PTEST_BINARY test.flo --header > test.h++
cat test.h++

time $PTEST_BINARY test.flo --compat > compat.c++
cat compat.c++

time clang -g -c -std=c++11 harness.c++ -o harness.llvm -S -emit-llvm
#cat harness.llvm

time clang -g -c -include test.h++ -std=c++11 compat.c++ \
    -o compat.llvm -S -emit-llvm
#cat compat.llvm

# Preforms the Flo->LLVM conversion to generate the actual clock
# lines.
time $PTEST_BINARY test.flo --ir > test.llvm
cat test.llvm

# Links together all the bitcode files
time llvm-link test.llvm compat.llvm harness.llvm -S > exe.llvm
#cat exe.llvm

# Optimizes the assembly that was generated.  I'm not sure if this is
# necessary to do before I stick in inside the JIT or not...
time opt -O3 exe.llvm -S > opt.llvm
#cat opt.llvm

# Runs the new emulator inside the LLVM interpreter (or probably JIT
# compiler, if you're using a sane architecture).
llc opt.llvm -o opt.S
c++ -g opt.S -o opt
if test -f test.stdin
then
    cp test.stdin test.stdin.copy
    time cat test.stdin.copy | ./opt
else
    time ./opt --vcd test.vcd --cycles 100
fi
cat test.vcd

# Ensures that the two VCD files are actually the same.  Note that
# this allows extra signals to exist in the test file, but at least
# every signal from the gold file must exist.
time vcddiff gold.vcd test.vcd
