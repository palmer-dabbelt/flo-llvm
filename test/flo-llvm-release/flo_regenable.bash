#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.flo <<"EOF"
reset = rst'1
test::io_en = in'1
test::io_out0 = out'3 Torture0
Torture3 = mux'3 reset 0 Torture1
Torture0 = reg'3 test::io_en Torture3
Torture2 = add 1 Torture0
Torture1 = mov Torture2
EOF

cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module test $end
$var wire 3 N0 io_out0 $end
$var wire 1 N1 io_en $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b000 N0
b1 N1
#1
b001 N0
#2
b010 N0
#3
b011 N0
#4
b100 N0
#5
b101 N0
#6
b110 N0
#7
b111 N0
#8
b000 N0
#9
b001 N0
#10
b010 N0
#11
b011 N0
#12
b100 N0
#13
b101 N0
#14
b110 N0
#15
b111 N0
#16
b000 N0
#17
b001 N0
#18
b010 N0
#19
b011 N0
#20
b100 N0
#21
b101 N0
#22
b110 N0
#23
b111 N0
#24
b000 N0
#25
b001 N0
#26
b010 N0
#27
b011 N0
#28
b100 N0
#29
b101 N0
#30
b110 N0
#31
b111 N0
#32
b000 N0
#33
b001 N0
#34
b010 N0
#35
b011 N0
#36
b100 N0
#37
b101 N0
#38
b110 N0
#39
b111 N0
#40
b000 N0
#41
b001 N0
#42
b010 N0
#43
b011 N0
#44
b100 N0
#45
b101 N0
#46
b110 N0
#47
b111 N0
#48
b000 N0
#49
b001 N0
#50
b010 N0
#51
b011 N0
#52
b100 N0
#53
b101 N0
#54
b110 N0
#55
b111 N0
#56
b000 N0
#57
b001 N0
#58
b010 N0
#59
b011 N0
#60
b100 N0
#61
b101 N0
#62
b110 N0
#63
b111 N0
#64
b000 N0
#65
b001 N0
#66
b010 N0
#67
b011 N0
#68
b100 N0
#69
b101 N0
#70
b110 N0
#71
b111 N0
#72
b000 N0
#73
b001 N0
#74
b010 N0
#75
b011 N0
#76
b100 N0
#77
b101 N0
#78
b110 N0
#79
b111 N0
#80
b000 N0
#81
b001 N0
#82
b010 N0
#83
b011 N0
#84
b100 N0
#85
b101 N0
#86
b110 N0
#87
b111 N0
#88
b000 N0
#89
b001 N0
#90
b010 N0
#91
b011 N0
#92
b100 N0
#93
b101 N0
#94
b110 N0
#95
b111 N0
#96
b000 N0
#97
b001 N0
#98
b010 N0
#99
b011 N0
#100
b0 N1
b100 N0
#101
b0 N1
#102
b0 N1
#103
b0 N1
#104
b0 N1
#105
b0 N1
#106
b0 N1
#107
b0 N1
EOF

#include "harness.bash"
