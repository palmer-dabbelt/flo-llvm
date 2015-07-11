#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="ShiftRegister"

cat >$TEST.flo <<"EOF"
ShiftRegister::in = in'8
ShiftRegister::reset = rst'1
ShiftRegister::r0 = reg'8 1'1 ShiftRegister::in
ShiftRegister::r1 = reg'8 1'1 ShiftRegister::r0
ShiftRegister::r2 = reg'8 1'1 ShiftRegister::r1
ShiftRegister::r3 = reg'8 1'1 ShiftRegister::r2
ShiftRegister::out = out'8 ShiftRegister::r3
EOF

cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module ShiftRegister $end
$upscope $end
$scope module ShiftRegister $end
$var wire 8 N0 in $end
$var wire 8 N2 out $end
$var wire 8 N6 r0 $end
$var wire 8 N5 r1 $end
$var wire 8 N4 r2 $end
$var wire 8 N3 r3 $end
$var wire 1 N1 reset $end
$upscope $end
$scope module _chisel_temps_ $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b00000000 N0
b00000000 N2
b00000000 N6
b00000000 N5
b00000000 N4
b00000000 N3
b0 N1
#1
#2
#3
#4
b00010000 N0
#5
b00100000 N0
b00010000 N6
#6
b01000000 N0
b00100000 N6
b00010000 N5
EOF

#include "harness.bash"
