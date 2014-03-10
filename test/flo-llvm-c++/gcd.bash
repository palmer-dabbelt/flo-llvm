#include "tempdir.bash"
#include "emulator.bash"

cat >test.flo <<EOF
reset = rst
GCDWrapper::gcd::reset = mov reset
T0 = add/32 GCDWrapper::cnt 1
GCDWrapper::gcd::io_bin = mov T0
T1 = not/1 GCDWrapper::gcd::busy
T2 = and T1 1
T3 = mux T2 GCDWrapper::gcd::io_bin GCDWrapper::gcd::b
T4 = sub/32 GCDWrapper::gcd::b GCDWrapper::gcd::a
T5 = lt/32 GCDWrapper::gcd::b GCDWrapper::gcd::a
T6 = eq GCDWrapper::gcd::a GCDWrapper::gcd::b
T7 = or T6 T5
T8 = not/1 T7
T9 = not/1 GCDWrapper::gcd::done
T10 = and GCDWrapper::gcd::busy T9
T11 = and T10 T8
T12 = mux T11 T4 T3
GCDWrapper::gcd::b__update = mux GCDWrapper::gcd::reset 0 T12
GCDWrapper::gcd::b = reg T12 GCDWrapper::gcd::b__update
T13 = mux T2 0 GCDWrapper::gcd::done
T14 = and T10 T6
T15 = mux T14 1 T13
T16 = and GCDWrapper::gcd::busy GCDWrapper::gcd::done
T17 = mux T16 0 T15
GCDWrapper::gcd::done__update = mux GCDWrapper::gcd::reset 0 T17
GCDWrapper::gcd::done = reg T17 GCDWrapper::gcd::done__update
T18 = mux T2 1 GCDWrapper::gcd::busy
T19 = mux T16 0 T18
GCDWrapper::gcd::busy__update = mux GCDWrapper::gcd::reset 0 T19
GCDWrapper::gcd::busy = reg T19 GCDWrapper::gcd::busy__update
GCDWrapper::gcd::io_ain = mov GCDWrapper::cnt
T20 = mux T2 GCDWrapper::gcd::io_ain GCDWrapper::gcd::a
T21 = sub/32 GCDWrapper::gcd::a GCDWrapper::gcd::b
T22 = not/1 T6
T23 = and T22 T5
T24 = and T10 T23
T25 = mux T24 T21 T20
GCDWrapper::gcd::a__update = mux GCDWrapper::gcd::reset 0 T25
GCDWrapper::gcd::a = reg T25 GCDWrapper::gcd::a__update
GCDWrapper::gcd::io_vld = mov T16
GCDWrapper::io_valid = out/1 GCDWrapper::gcd::io_vld
T26 = add/32 GCDWrapper::cnt 1
GCDWrapper::cnt__update = mux reset 0 T26
GCDWrapper::cnt = reg T26 GCDWrapper::cnt__update
GCDWrapper::gcd::io_out = mov GCDWrapper::gcd::a
GCDWrapper::io_data = out/32 GCDWrapper::gcd::io_out
EOF

cat >harness.c++ <<EOF
 #include "test.h"

int main(int argc, const char **argv)
{
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

    GCDWrapper_t dut;
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

cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module Fib $end
$var wire 1 N0 io_ok $end
$var wire 32 N1 io_in $end
$var wire 1 N2 reset $end
$var wire 32 N3 cycle $end
$var wire 32 N4 range $end
$var wire 32 N5 index $end
$var wire 1 N6 valid $end
$var wire 32 N7 sum1 $end
$var wire 32 N8 sum0 $end
$var wire 32 N9 io_ot $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b1 N0
b00000000000000000000000000000000 N1
b00000000000000000000000000000010 N3
b00000000000000000000000000000010 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000000000 N9
#1
b0 N0
b00000000000000000000000000000010 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
#2
b00000000000000000000000000000011 N3
b00000000000000000000000000000011 N5
b1 N6
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#3
b1 N0
b00000000000000000000000000000011 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
#4
b0 N0
b00000000000000000000000000000011 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#5
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#6
b00000000000000000000000000000100 N3
b00000000000000000000000000000100 N5
b1 N6
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#7
b1 N0
b00000000000000000000000000000100 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000000010 N9
#8
b0 N0
b00000000000000000000000000000100 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#9
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#10
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#11
b00000000000000000000000000000101 N3
b00000000000000000000000000000101 N5
b1 N6
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#12
b1 N0
b00000000000000000000000000000101 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000000011 N9
#13
b0 N0
b00000000000000000000000000000101 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#14
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#15
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#16
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#17
b00000000000000000000000000000110 N3
b00000000000000000000000000000110 N5
b1 N6
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#18
b1 N0
b00000000000000000000000000000110 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000000101 N9
#19
b0 N0
b00000000000000000000000000000110 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#20
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#21
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#22
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#23
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#24
b00000000000000000000000000000111 N3
b00000000000000000000000000000111 N5
b1 N6
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#25
b1 N0
b00000000000000000000000000000111 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000001000 N9
#26
b0 N0
b00000000000000000000000000000111 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#27
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#28
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#29
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#30
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#31
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#32
b00000000000000000000000000001000 N3
b00000000000000000000000000001000 N5
b1 N6
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#33
b1 N0
b00000000000000000000000000001000 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000001101 N9
#34
b0 N0
b00000000000000000000000000001000 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#35
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#36
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#37
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#38
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#39
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#40
b00000000000000000000000000001000 N5
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#41
b00000000000000000000000000001001 N3
b00000000000000000000000000001001 N5
b1 N6
b00000000000000000000000000100010 N7
b00000000000000000000000000010101 N8
b00000000000000000000000000001101 N9
#42
b1 N0
b00000000000000000000000000001001 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000010101 N9
#43
b0 N0
b00000000000000000000000000001001 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#44
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#45
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#46
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#47
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#48
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#49
b00000000000000000000000000001000 N5
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#50
b00000000000000000000000000001001 N5
b00000000000000000000000000100010 N7
b00000000000000000000000000010101 N8
b00000000000000000000000000001101 N9
#51
b00000000000000000000000000001010 N3
b00000000000000000000000000001010 N5
b1 N6
b00000000000000000000000000110111 N7
b00000000000000000000000000100010 N8
b00000000000000000000000000010101 N9
#52
b1 N0
b00000000000000000000000000001010 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000100010 N9
#53
b0 N0
b00000000000000000000000000001010 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#54
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#55
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#56
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#57
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#58
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#59
b00000000000000000000000000001000 N5
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#60
b00000000000000000000000000001001 N5
b00000000000000000000000000100010 N7
b00000000000000000000000000010101 N8
b00000000000000000000000000001101 N9
#61
b00000000000000000000000000001010 N5
b00000000000000000000000000110111 N7
b00000000000000000000000000100010 N8
b00000000000000000000000000010101 N9
#62
b00000000000000000000000000001011 N3
b00000000000000000000000000001011 N5
b1 N6
b00000000000000000000000001011001 N7
b00000000000000000000000000110111 N8
b00000000000000000000000000100010 N9
#63
b1 N0
b00000000000000000000000000001011 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000000110111 N9
#64
b0 N0
b00000000000000000000000000001011 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#65
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#66
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#67
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#68
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#69
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#70
b00000000000000000000000000001000 N5
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#71
b00000000000000000000000000001001 N5
b00000000000000000000000000100010 N7
b00000000000000000000000000010101 N8
b00000000000000000000000000001101 N9
#72
b00000000000000000000000000001010 N5
b00000000000000000000000000110111 N7
b00000000000000000000000000100010 N8
b00000000000000000000000000010101 N9
#73
b00000000000000000000000000001011 N5
b00000000000000000000000001011001 N7
b00000000000000000000000000110111 N8
b00000000000000000000000000100010 N9
#74
b00000000000000000000000000001100 N3
b00000000000000000000000000001100 N5
b1 N6
b00000000000000000000000010010000 N7
b00000000000000000000000001011001 N8
b00000000000000000000000000110111 N9
#75
b1 N0
b00000000000000000000000000001100 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000001011001 N9
#76
b0 N0
b00000000000000000000000000001100 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#77
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#78
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#79
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#80
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#81
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#82
b00000000000000000000000000001000 N5
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#83
b00000000000000000000000000001001 N5
b00000000000000000000000000100010 N7
b00000000000000000000000000010101 N8
b00000000000000000000000000001101 N9
#84
b00000000000000000000000000001010 N5
b00000000000000000000000000110111 N7
b00000000000000000000000000100010 N8
b00000000000000000000000000010101 N9
#85
b00000000000000000000000000001011 N5
b00000000000000000000000001011001 N7
b00000000000000000000000000110111 N8
b00000000000000000000000000100010 N9
#86
b00000000000000000000000000001100 N5
b00000000000000000000000010010000 N7
b00000000000000000000000001011001 N8
b00000000000000000000000000110111 N9
#87
b00000000000000000000000000001101 N3
b00000000000000000000000000001101 N5
b1 N6
b00000000000000000000000011101001 N7
b00000000000000000000000010010000 N8
b00000000000000000000000001011001 N9
#88
b1 N0
b00000000000000000000000000001101 N4
b00000000000000000000000000000001 N5
b0 N6
b00000000000000000000000000000001 N7
b00000000000000000000000000000000 N8
b00000000000000000000000010010000 N9
#89
b0 N0
b00000000000000000000000000001101 N1
b00000000000000000000000000000010 N5
b00000000000000000000000000000001 N8
b00000000000000000000000000000000 N9
#90
b00000000000000000000000000000011 N5
b00000000000000000000000000000010 N7
b00000000000000000000000000000001 N9
#91
b00000000000000000000000000000100 N5
b00000000000000000000000000000011 N7
b00000000000000000000000000000010 N8
#92
b00000000000000000000000000000101 N5
b00000000000000000000000000000101 N7
b00000000000000000000000000000011 N8
b00000000000000000000000000000010 N9
#93
b00000000000000000000000000000110 N5
b00000000000000000000000000001000 N7
b00000000000000000000000000000101 N8
b00000000000000000000000000000011 N9
#94
b00000000000000000000000000000111 N5
b00000000000000000000000000001101 N7
b00000000000000000000000000001000 N8
b00000000000000000000000000000101 N9
#95
b00000000000000000000000000001000 N5
b00000000000000000000000000010101 N7
b00000000000000000000000000001101 N8
b00000000000000000000000000001000 N9
#96
b00000000000000000000000000001001 N5
b00000000000000000000000000100010 N7
b00000000000000000000000000010101 N8
b00000000000000000000000000001101 N9
#97
b00000000000000000000000000001010 N5
b00000000000000000000000000110111 N7
b00000000000000000000000000100010 N8
b00000000000000000000000000010101 N9
#98
b00000000000000000000000000001011 N5
b00000000000000000000000001011001 N7
b00000000000000000000000000110111 N8
b00000000000000000000000000100010 N9
EOF

cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module GCDWrapper $end
$var wire 1 N0 reset $end
$var wire 1 N10 io_valid $end
$var wire 32 N11 cnt $end
$var wire 32 N13 io_data $end
$scope module gcd $end
$var wire 1 N1 reset $end
$var wire 32 N2 io_bin $end
$var wire 1 N3 io_rdy $end
$var wire 32 N4 b $end
$var wire 1 N5 done $end
$var wire 1 N6 busy $end
$var wire 32 N7 io_ain $end
$var wire 32 N8 a $end
$var wire 1 N9 io_vld $end
$var wire 32 N12 io_out $end
$upscope $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b0 N1
b00000000000000000000000000000001 N2
b1 N3
b00000000000000000000000000000001 N4
b0 N5
b1 N6
b00000000000000000000000000000000 N7
b00000000000000000000000000000000 N8
b0 N9
b0 N10
b00000000000000000000000000000001 N11
b00000000000000000000000000000000 N12
b00000000000000000000000000000000 N13
#1
b00000000000000000000000000000010 N2
b00000000000000000000000000000001 N7
b00000000000000000000000000000010 N11
#2
b00000000000000000000000000000011 N2
b00000000000000000000000000000010 N7
b00000000000000000000000000000011 N11
#3
b00000000000000000000000000000100 N2
b00000000000000000000000000000011 N7
b00000000000000000000000000000100 N11
#4
b00000000000000000000000000000101 N2
b00000000000000000000000000000100 N7
b00000000000000000000000000000101 N11
#5
b00000000000000000000000000000110 N2
b00000000000000000000000000000101 N7
b00000000000000000000000000000110 N11
#6
b00000000000000000000000000000111 N2
b00000000000000000000000000000110 N7
b00000000000000000000000000000111 N11
#7
b00000000000000000000000000001000 N2
b00000000000000000000000000000111 N7
b00000000000000000000000000001000 N11
#8
b00000000000000000000000000001001 N2
b00000000000000000000000000001000 N7
b00000000000000000000000000001001 N11
#9
b00000000000000000000000000001010 N2
b00000000000000000000000000001001 N7
b00000000000000000000000000001010 N11
#10
b00000000000000000000000000001011 N2
b00000000000000000000000000001010 N7
b00000000000000000000000000001011 N11
#11
b00000000000000000000000000001100 N2
b00000000000000000000000000001011 N7
b00000000000000000000000000001100 N11
#12
b00000000000000000000000000001101 N2
b00000000000000000000000000001100 N7
b00000000000000000000000000001101 N11
#13
b00000000000000000000000000001110 N2
b00000000000000000000000000001101 N7
b00000000000000000000000000001110 N11
#14
b00000000000000000000000000001111 N2
b00000000000000000000000000001110 N7
b00000000000000000000000000001111 N11
#15
b00000000000000000000000000010000 N2
b00000000000000000000000000001111 N7
b00000000000000000000000000010000 N11
#16
b00000000000000000000000000010001 N2
b00000000000000000000000000010000 N7
b00000000000000000000000000010001 N11
#17
b00000000000000000000000000010010 N2
b00000000000000000000000000010001 N7
b00000000000000000000000000010010 N11
#18
b00000000000000000000000000010011 N2
b00000000000000000000000000010010 N7
b00000000000000000000000000010011 N11
#19
b00000000000000000000000000010100 N2
b00000000000000000000000000010011 N7
b00000000000000000000000000010100 N11
#20
b00000000000000000000000000010101 N2
b00000000000000000000000000010100 N7
b00000000000000000000000000010101 N11
#21
b00000000000000000000000000010110 N2
b00000000000000000000000000010101 N7
b00000000000000000000000000010110 N11
#22
b00000000000000000000000000010111 N2
b00000000000000000000000000010110 N7
b00000000000000000000000000010111 N11
#23
b00000000000000000000000000011000 N2
b00000000000000000000000000010111 N7
b00000000000000000000000000011000 N11
#24
b00000000000000000000000000011001 N2
b00000000000000000000000000011000 N7
b00000000000000000000000000011001 N11
#25
b00000000000000000000000000011010 N2
b00000000000000000000000000011001 N7
b00000000000000000000000000011010 N11
#26
b00000000000000000000000000011011 N2
b00000000000000000000000000011010 N7
b00000000000000000000000000011011 N11
#27
b00000000000000000000000000011100 N2
b00000000000000000000000000011011 N7
b00000000000000000000000000011100 N11
#28
b00000000000000000000000000011101 N2
b00000000000000000000000000011100 N7
b00000000000000000000000000011101 N11
#29
b00000000000000000000000000011110 N2
b00000000000000000000000000011101 N7
b00000000000000000000000000011110 N11
#30
b00000000000000000000000000011111 N2
b00000000000000000000000000011110 N7
b00000000000000000000000000011111 N11
#31
b00000000000000000000000000100000 N2
b00000000000000000000000000011111 N7
b00000000000000000000000000100000 N11
#32
b00000000000000000000000000100001 N2
b00000000000000000000000000100000 N7
b00000000000000000000000000100001 N11
#33
b00000000000000000000000000100010 N2
b00000000000000000000000000100001 N7
b00000000000000000000000000100010 N11
#34
b00000000000000000000000000100011 N2
b00000000000000000000000000100010 N7
b00000000000000000000000000100011 N11
#35
b00000000000000000000000000100100 N2
b00000000000000000000000000100011 N7
b00000000000000000000000000100100 N11
#36
b00000000000000000000000000100101 N2
b00000000000000000000000000100100 N7
b00000000000000000000000000100101 N11
#37
b00000000000000000000000000100110 N2
b00000000000000000000000000100101 N7
b00000000000000000000000000100110 N11
#38
b00000000000000000000000000100111 N2
b00000000000000000000000000100110 N7
b00000000000000000000000000100111 N11
#39
b00000000000000000000000000101000 N2
b00000000000000000000000000100111 N7
b00000000000000000000000000101000 N11
#40
b00000000000000000000000000101001 N2
b00000000000000000000000000101000 N7
b00000000000000000000000000101001 N11
#41
b00000000000000000000000000101010 N2
b00000000000000000000000000101001 N7
b00000000000000000000000000101010 N11
#42
b00000000000000000000000000101011 N2
b00000000000000000000000000101010 N7
b00000000000000000000000000101011 N11
#43
b00000000000000000000000000101100 N2
b00000000000000000000000000101011 N7
b00000000000000000000000000101100 N11
#44
b00000000000000000000000000101101 N2
b00000000000000000000000000101100 N7
b00000000000000000000000000101101 N11
#45
b00000000000000000000000000101110 N2
b00000000000000000000000000101101 N7
b00000000000000000000000000101110 N11
#46
b00000000000000000000000000101111 N2
b00000000000000000000000000101110 N7
b00000000000000000000000000101111 N11
#47
b00000000000000000000000000110000 N2
b00000000000000000000000000101111 N7
b00000000000000000000000000110000 N11
#48
b00000000000000000000000000110001 N2
b00000000000000000000000000110000 N7
b00000000000000000000000000110001 N11
#49
b00000000000000000000000000110010 N2
b00000000000000000000000000110001 N7
b00000000000000000000000000110010 N11
#50
b00000000000000000000000000110011 N2
b00000000000000000000000000110010 N7
b00000000000000000000000000110011 N11
#51
b00000000000000000000000000110100 N2
b00000000000000000000000000110011 N7
b00000000000000000000000000110100 N11
#52
b00000000000000000000000000110101 N2
b00000000000000000000000000110100 N7
b00000000000000000000000000110101 N11
#53
b00000000000000000000000000110110 N2
b00000000000000000000000000110101 N7
b00000000000000000000000000110110 N11
#54
b00000000000000000000000000110111 N2
b00000000000000000000000000110110 N7
b00000000000000000000000000110111 N11
#55
b00000000000000000000000000111000 N2
b00000000000000000000000000110111 N7
b00000000000000000000000000111000 N11
#56
b00000000000000000000000000111001 N2
b00000000000000000000000000111000 N7
b00000000000000000000000000111001 N11
#57
b00000000000000000000000000111010 N2
b00000000000000000000000000111001 N7
b00000000000000000000000000111010 N11
#58
b00000000000000000000000000111011 N2
b00000000000000000000000000111010 N7
b00000000000000000000000000111011 N11
#59
b00000000000000000000000000111100 N2
b00000000000000000000000000111011 N7
b00000000000000000000000000111100 N11
#60
b00000000000000000000000000111101 N2
b00000000000000000000000000111100 N7
b00000000000000000000000000111101 N11
#61
b00000000000000000000000000111110 N2
b00000000000000000000000000111101 N7
b00000000000000000000000000111110 N11
#62
b00000000000000000000000000111111 N2
b00000000000000000000000000111110 N7
b00000000000000000000000000111111 N11
#63
b00000000000000000000000001000000 N2
b00000000000000000000000000111111 N7
b00000000000000000000000001000000 N11
#64
b00000000000000000000000001000001 N2
b00000000000000000000000001000000 N7
b00000000000000000000000001000001 N11
#65
b00000000000000000000000001000010 N2
b00000000000000000000000001000001 N7
b00000000000000000000000001000010 N11
#66
b00000000000000000000000001000011 N2
b00000000000000000000000001000010 N7
b00000000000000000000000001000011 N11
#67
b00000000000000000000000001000100 N2
b00000000000000000000000001000011 N7
b00000000000000000000000001000100 N11
#68
b00000000000000000000000001000101 N2
b00000000000000000000000001000100 N7
b00000000000000000000000001000101 N11
#69
b00000000000000000000000001000110 N2
b00000000000000000000000001000101 N7
b00000000000000000000000001000110 N11
#70
b00000000000000000000000001000111 N2
b00000000000000000000000001000110 N7
b00000000000000000000000001000111 N11
#71
b00000000000000000000000001001000 N2
b00000000000000000000000001000111 N7
b00000000000000000000000001001000 N11
#72
b00000000000000000000000001001001 N2
b00000000000000000000000001001000 N7
b00000000000000000000000001001001 N11
#73
b00000000000000000000000001001010 N2
b00000000000000000000000001001001 N7
b00000000000000000000000001001010 N11
#74
b00000000000000000000000001001011 N2
b00000000000000000000000001001010 N7
b00000000000000000000000001001011 N11
#75
b00000000000000000000000001001100 N2
b00000000000000000000000001001011 N7
b00000000000000000000000001001100 N11
#76
b00000000000000000000000001001101 N2
b00000000000000000000000001001100 N7
b00000000000000000000000001001101 N11
#77
b00000000000000000000000001001110 N2
b00000000000000000000000001001101 N7
b00000000000000000000000001001110 N11
#78
b00000000000000000000000001001111 N2
b00000000000000000000000001001110 N7
b00000000000000000000000001001111 N11
#79
b00000000000000000000000001010000 N2
b00000000000000000000000001001111 N7
b00000000000000000000000001010000 N11
#80
b00000000000000000000000001010001 N2
b00000000000000000000000001010000 N7
b00000000000000000000000001010001 N11
#81
b00000000000000000000000001010010 N2
b00000000000000000000000001010001 N7
b00000000000000000000000001010010 N11
#82
b00000000000000000000000001010011 N2
b00000000000000000000000001010010 N7
b00000000000000000000000001010011 N11
#83
b00000000000000000000000001010100 N2
b00000000000000000000000001010011 N7
b00000000000000000000000001010100 N11
#84
b00000000000000000000000001010101 N2
b00000000000000000000000001010100 N7
b00000000000000000000000001010101 N11
#85
b00000000000000000000000001010110 N2
b00000000000000000000000001010101 N7
b00000000000000000000000001010110 N11
#86
b00000000000000000000000001010111 N2
b00000000000000000000000001010110 N7
b00000000000000000000000001010111 N11
#87
b00000000000000000000000001011000 N2
b00000000000000000000000001010111 N7
b00000000000000000000000001011000 N11
#88
b00000000000000000000000001011001 N2
b00000000000000000000000001011000 N7
b00000000000000000000000001011001 N11
#89
b00000000000000000000000001011010 N2
b00000000000000000000000001011001 N7
b00000000000000000000000001011010 N11
#90
b00000000000000000000000001011011 N2
b00000000000000000000000001011010 N7
b00000000000000000000000001011011 N11
#91
b00000000000000000000000001011100 N2
b00000000000000000000000001011011 N7
b00000000000000000000000001011100 N11
#92
b00000000000000000000000001011101 N2
b00000000000000000000000001011100 N7
b00000000000000000000000001011101 N11
#93
b00000000000000000000000001011110 N2
b00000000000000000000000001011101 N7
b00000000000000000000000001011110 N11
#94
b00000000000000000000000001011111 N2
b00000000000000000000000001011110 N7
b00000000000000000000000001011111 N11
#95
b00000000000000000000000001100000 N2
b00000000000000000000000001011111 N7
b00000000000000000000000001100000 N11
#96
b00000000000000000000000001100001 N2
b00000000000000000000000001100000 N7
b00000000000000000000000001100001 N11
#97
b00000000000000000000000001100010 N2
b00000000000000000000000001100001 N7
b00000000000000000000000001100010 N11
#98
b00000000000000000000000001100011 N2
b00000000000000000000000001100010 N7
b00000000000000000000000001100011 N11
EOF

#include "harness.bash"
