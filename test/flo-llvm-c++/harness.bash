# Builds the rest of the C++ emulator, which contains a main() that
# actually runs the code.
$PTEST_BINARY test.flo --header > test.h++
cat test.h++

$PTEST_BINARY test.flo --compat > compat.c++
cat compat.c++

clang -c -std=c++11 harness.c++ -o harness.llvm -S -emit-llvm
#cat harness.llvm

clang -c -include test.h++ -std=c++11 compat.c++ -o compat.llvm -S -emit-llvm
#cat compat.llvm

# Preforms the Flo->LLVM conversion to generate the actual clock
# lines.
$PTEST_BINARY test.flo --ir > test.llvm
cat test.llvm

# Links together all the bitcode files
llvm-link test.llvm compat.llvm harness.llvm -S > exe.llvm
#cat exe.llvm

# Optimizes the assembly that was generated.  I'm not sure if this is
# necessary to do before I stick in inside the JIT or not...
opt -O3 exe.llvm -S > opt.llvm
cat opt.llvm

# Runs the new emulator inside the LLVM interpreter (or probably JIT
# compiler, if you're using a sane architecture).
lli opt.llvm --vcd test.vcd --cycles 100
cat test.vcd
