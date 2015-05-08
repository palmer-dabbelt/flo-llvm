#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.flo <<"EOF"
reset = rst'1
test::io_in = in'4
T0 = arsh'8 test::io_in 0
test::io_out = out'8 T0
EOF

cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module test $end
$var wire 4 in io_in $end
$var wire 8 out io_out $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b1111 in
b11111111 out
#1
b0111 in
b00000111 out
#2
b1111 in
b11111111 out
#3
b0111 in
b00000111 out
EOF

#include "harness.bash"
