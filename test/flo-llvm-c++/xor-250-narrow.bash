#include "tempdir.bash"
#include "emulator.bash"

cat > test.flo <<EOF
reset = rst/1
test::r.0 = reg/32 1 test::r__update.0
test::r.1 = reg/32 0 test::r__update.1
test::r.2 = reg/32 0 test::r__update.2
test::r.3 = reg/32 0 test::r__update.3
test::r.4 = reg/32 0 test::r__update.4
test::r.5 = reg/32 0 test::r__update.5
test::r.6 = reg/32 0 test::r__update.6
test::r.7 = reg/26 0 test::r__update.7
T0.0 = xor/32 test::r.0 test::r.0
T0.1 = xor/32 test::r.1 test::r.1
T0.2 = xor/32 test::r.2 test::r.2
T0.3 = xor/32 test::r.3 test::r.3
T0.4 = xor/32 test::r.4 test::r.4
T0.5 = xor/32 test::r.5 test::r.5
T0.6 = xor/32 test::r.6 test::r.6
T0.7 = xor/26 test::r.7 test::r.7
test::io_o.0 = out/32 test::r.0
test::io_o.1 = out/32 test::r.1
test::io_o.2 = out/32 test::r.2
test::io_o.3 = out/32 test::r.3
test::io_o.4 = out/32 test::r.4
test::io_o.5 = out/32 test::r.5
test::io_o.6 = out/32 test::r.6
test::io_o.7 = out/26 test::r.7
test::r__update.0 = mux/32 reset 0 T0.0
test::r__update.1 = mux/32 reset 0 T0.1
test::r__update.2 = mux/32 reset 0 T0.2
test::r__update.3 = mux/32 reset 0 T0.3
test::r__update.4 = mux/32 reset 0 T0.4
test::r__update.5 = mux/32 reset 0 T0.5
test::r__update.6 = mux/32 reset 0 T0.6
test::r__update.7 = mux/26 reset 0 T0.7
EOF

cat > harness.c++ <<EOF
 #include "test.h++"
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>

int main(int argc, char **argv) {
    int cycles = 0;
    const char *vcd_file = "/dev/null";

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--vcd") == 0) {
            i++;
            vcd_file = argv[i];
        } else if (strcmp(argv[i], "--cycles") == 0) {
            i++;
            cycles = atoi(argv[i]);
        } else {
            fprintf(stderr, "Unable to parse argument '%s'\n", argv[i]);
            abort();
        }
    }

    test_t dut;
    dut.init(false);

    FILE *vcd = fopen(vcd_file, "w");

    for (int cycle = 0; cycle < cycles; cycle++) {
        dut.clock_lo(cycle == 0);
        dut.clock_hi(cycle == 0);
        if (cycle > 0)
            dut.dump(vcd, cycle - 1);
    }

    fclose(vcd);

    return 0;
}
EOF

cat >>gold.vcd <<"EOF"
$timescale 1ps $end
$scope module test $end
$var wire 32 N17 io_o.0 $end
$var wire 32 N18 io_o.1 $end
$var wire 32 N19 io_o.2 $end
$var wire 32 N20 io_o.3 $end
$var wire 32 N21 io_o.4 $end
$var wire 32 N22 io_o.5 $end
$var wire 32 N23 io_o.6 $end
$var wire 26 N24 io_o.7 $end
$var wire 32 N1 r.0 $end
$var wire 32 N2 r.1 $end
$var wire 32 N3 r.2 $end
$var wire 32 N4 r.3 $end
$var wire 32 N5 r.4 $end
$var wire 32 N6 r.5 $end
$var wire 32 N7 r.6 $end
$var wire 26 N8 r.7 $end
$var wire 32 N25 r__update.0 $end
$var wire 32 N26 r__update.1 $end
$var wire 32 N27 r__update.2 $end
$var wire 32 N28 r__update.3 $end
$var wire 32 N29 r__update.4 $end
$var wire 32 N30 r__update.5 $end
$var wire 32 N31 r__update.6 $end
$var wire 26 N32 r__update.7 $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b00000000000000000000000000000000 N17
b00000000000000000000000000000000 N18
b00000000000000000000000000000000 N19
b00000000000000000000000000000000 N20
b00000000000000000000000000000000 N21
b00000000000000000000000000000000 N22
b00000000000000000000000000000000 N23
b00000000000000000000000000 N24
b00000000000000000000000000000000 N1
b00000000000000000000000000000000 N2
b00000000000000000000000000000000 N3
b00000000000000000000000000000000 N4
b00000000000000000000000000000000 N5
b00000000000000000000000000000000 N6
b00000000000000000000000000000000 N7
b00000000000000000000000000 N8
b00000000000000000000000000000000 N25
b00000000000000000000000000000000 N26
b00000000000000000000000000000000 N27
b00000000000000000000000000000000 N28
b00000000000000000000000000000000 N29
b00000000000000000000000000000000 N30
b00000000000000000000000000000000 N31
b00000000000000000000000000 N32
#1
#2
#3
#4
#5
#6
#7
#8
#9
#10
#11
#12
#13
#14
#15
#16
#17
#18
#19
#20
#21
#22
#23
#24
#25
#26
#27
#28
#29
#30
#31
#32
#33
#34
#35
#36
#37
#38
#39
#40
#41
#42
#43
#44
#45
#46
#47
#48
#49
#50
#51
#52
#53
#54
#55
#56
#57
#58
#59
#60
#61
#62
#63
#64
#65
#66
#67
#68
#69
#70
#71
#72
#73
#74
#75
#76
#77
#78
#79
#80
#81
#82
#83
#84
#85
#86
#87
#88
#89
#90
#91
#92
#93
#94
#95
#96
#97
#98
EOF

#include "harness.bash"
