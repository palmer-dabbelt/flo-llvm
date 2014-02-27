#include "tempdir.bash"
#include "emulator.bash"

cat > test.flo <<EOF
reset = rst
T0 = add/64 Counter64::reg 1
Counter64::reg__update = mux reset 0 T0
Counter64::reg = reg T0 Counter64::reg__update
Counter64::io_count = out/64 Counter64::reg
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

    Counter64_t dut;
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
$scope module Counter64 $end
$var wire 1 N0 reset $end
$var wire 64 N1 reg $end
$var wire 64 N2 io_count $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b0000000000000000000000000000000000000000000000000000000000000001 N1
b0000000000000000000000000000000000000000000000000000000000000000 N2
#1
b0000000000000000000000000000000000000000000000000000000000000010 N1
b0000000000000000000000000000000000000000000000000000000000000001 N2
#2
b0000000000000000000000000000000000000000000000000000000000000011 N1
b0000000000000000000000000000000000000000000000000000000000000010 N2
#3
b0000000000000000000000000000000000000000000000000000000000000100 N1
b0000000000000000000000000000000000000000000000000000000000000011 N2
#4
b0000000000000000000000000000000000000000000000000000000000000101 N1
b0000000000000000000000000000000000000000000000000000000000000100 N2
#5
b0000000000000000000000000000000000000000000000000000000000000110 N1
b0000000000000000000000000000000000000000000000000000000000000101 N2
#6
b0000000000000000000000000000000000000000000000000000000000000111 N1
b0000000000000000000000000000000000000000000000000000000000000110 N2
#7
b0000000000000000000000000000000000000000000000000000000000001000 N1
b0000000000000000000000000000000000000000000000000000000000000111 N2
#8
b0000000000000000000000000000000000000000000000000000000000001001 N1
b0000000000000000000000000000000000000000000000000000000000001000 N2
#9
b0000000000000000000000000000000000000000000000000000000000001010 N1
b0000000000000000000000000000000000000000000000000000000000001001 N2
#10
b0000000000000000000000000000000000000000000000000000000000001011 N1
b0000000000000000000000000000000000000000000000000000000000001010 N2
#11
b0000000000000000000000000000000000000000000000000000000000001100 N1
b0000000000000000000000000000000000000000000000000000000000001011 N2
#12
b0000000000000000000000000000000000000000000000000000000000001101 N1
b0000000000000000000000000000000000000000000000000000000000001100 N2
#13
b0000000000000000000000000000000000000000000000000000000000001110 N1
b0000000000000000000000000000000000000000000000000000000000001101 N2
#14
b0000000000000000000000000000000000000000000000000000000000001111 N1
b0000000000000000000000000000000000000000000000000000000000001110 N2
#15
b0000000000000000000000000000000000000000000000000000000000010000 N1
b0000000000000000000000000000000000000000000000000000000000001111 N2
#16
b0000000000000000000000000000000000000000000000000000000000010001 N1
b0000000000000000000000000000000000000000000000000000000000010000 N2
#17
b0000000000000000000000000000000000000000000000000000000000010010 N1
b0000000000000000000000000000000000000000000000000000000000010001 N2
#18
b0000000000000000000000000000000000000000000000000000000000010011 N1
b0000000000000000000000000000000000000000000000000000000000010010 N2
#19
b0000000000000000000000000000000000000000000000000000000000010100 N1
b0000000000000000000000000000000000000000000000000000000000010011 N2
#20
b0000000000000000000000000000000000000000000000000000000000010101 N1
b0000000000000000000000000000000000000000000000000000000000010100 N2
#21
b0000000000000000000000000000000000000000000000000000000000010110 N1
b0000000000000000000000000000000000000000000000000000000000010101 N2
#22
b0000000000000000000000000000000000000000000000000000000000010111 N1
b0000000000000000000000000000000000000000000000000000000000010110 N2
#23
b0000000000000000000000000000000000000000000000000000000000011000 N1
b0000000000000000000000000000000000000000000000000000000000010111 N2
#24
b0000000000000000000000000000000000000000000000000000000000011001 N1
b0000000000000000000000000000000000000000000000000000000000011000 N2
#25
b0000000000000000000000000000000000000000000000000000000000011010 N1
b0000000000000000000000000000000000000000000000000000000000011001 N2
#26
b0000000000000000000000000000000000000000000000000000000000011011 N1
b0000000000000000000000000000000000000000000000000000000000011010 N2
#27
b0000000000000000000000000000000000000000000000000000000000011100 N1
b0000000000000000000000000000000000000000000000000000000000011011 N2
#28
b0000000000000000000000000000000000000000000000000000000000011101 N1
b0000000000000000000000000000000000000000000000000000000000011100 N2
#29
b0000000000000000000000000000000000000000000000000000000000011110 N1
b0000000000000000000000000000000000000000000000000000000000011101 N2
#30
b0000000000000000000000000000000000000000000000000000000000011111 N1
b0000000000000000000000000000000000000000000000000000000000011110 N2
#31
b0000000000000000000000000000000000000000000000000000000000100000 N1
b0000000000000000000000000000000000000000000000000000000000011111 N2
#32
b0000000000000000000000000000000000000000000000000000000000100001 N1
b0000000000000000000000000000000000000000000000000000000000100000 N2
#33
b0000000000000000000000000000000000000000000000000000000000100010 N1
b0000000000000000000000000000000000000000000000000000000000100001 N2
#34
b0000000000000000000000000000000000000000000000000000000000100011 N1
b0000000000000000000000000000000000000000000000000000000000100010 N2
#35
b0000000000000000000000000000000000000000000000000000000000100100 N1
b0000000000000000000000000000000000000000000000000000000000100011 N2
#36
b0000000000000000000000000000000000000000000000000000000000100101 N1
b0000000000000000000000000000000000000000000000000000000000100100 N2
#37
b0000000000000000000000000000000000000000000000000000000000100110 N1
b0000000000000000000000000000000000000000000000000000000000100101 N2
#38
b0000000000000000000000000000000000000000000000000000000000100111 N1
b0000000000000000000000000000000000000000000000000000000000100110 N2
#39
b0000000000000000000000000000000000000000000000000000000000101000 N1
b0000000000000000000000000000000000000000000000000000000000100111 N2
#40
b0000000000000000000000000000000000000000000000000000000000101001 N1
b0000000000000000000000000000000000000000000000000000000000101000 N2
#41
b0000000000000000000000000000000000000000000000000000000000101010 N1
b0000000000000000000000000000000000000000000000000000000000101001 N2
#42
b0000000000000000000000000000000000000000000000000000000000101011 N1
b0000000000000000000000000000000000000000000000000000000000101010 N2
#43
b0000000000000000000000000000000000000000000000000000000000101100 N1
b0000000000000000000000000000000000000000000000000000000000101011 N2
#44
b0000000000000000000000000000000000000000000000000000000000101101 N1
b0000000000000000000000000000000000000000000000000000000000101100 N2
#45
b0000000000000000000000000000000000000000000000000000000000101110 N1
b0000000000000000000000000000000000000000000000000000000000101101 N2
#46
b0000000000000000000000000000000000000000000000000000000000101111 N1
b0000000000000000000000000000000000000000000000000000000000101110 N2
#47
b0000000000000000000000000000000000000000000000000000000000110000 N1
b0000000000000000000000000000000000000000000000000000000000101111 N2
#48
b0000000000000000000000000000000000000000000000000000000000110001 N1
b0000000000000000000000000000000000000000000000000000000000110000 N2
#49
b0000000000000000000000000000000000000000000000000000000000110010 N1
b0000000000000000000000000000000000000000000000000000000000110001 N2
#50
b0000000000000000000000000000000000000000000000000000000000110011 N1
b0000000000000000000000000000000000000000000000000000000000110010 N2
#51
b0000000000000000000000000000000000000000000000000000000000110100 N1
b0000000000000000000000000000000000000000000000000000000000110011 N2
#52
b0000000000000000000000000000000000000000000000000000000000110101 N1
b0000000000000000000000000000000000000000000000000000000000110100 N2
#53
b0000000000000000000000000000000000000000000000000000000000110110 N1
b0000000000000000000000000000000000000000000000000000000000110101 N2
#54
b0000000000000000000000000000000000000000000000000000000000110111 N1
b0000000000000000000000000000000000000000000000000000000000110110 N2
#55
b0000000000000000000000000000000000000000000000000000000000111000 N1
b0000000000000000000000000000000000000000000000000000000000110111 N2
#56
b0000000000000000000000000000000000000000000000000000000000111001 N1
b0000000000000000000000000000000000000000000000000000000000111000 N2
#57
b0000000000000000000000000000000000000000000000000000000000111010 N1
b0000000000000000000000000000000000000000000000000000000000111001 N2
#58
b0000000000000000000000000000000000000000000000000000000000111011 N1
b0000000000000000000000000000000000000000000000000000000000111010 N2
#59
b0000000000000000000000000000000000000000000000000000000000111100 N1
b0000000000000000000000000000000000000000000000000000000000111011 N2
#60
b0000000000000000000000000000000000000000000000000000000000111101 N1
b0000000000000000000000000000000000000000000000000000000000111100 N2
#61
b0000000000000000000000000000000000000000000000000000000000111110 N1
b0000000000000000000000000000000000000000000000000000000000111101 N2
#62
b0000000000000000000000000000000000000000000000000000000000111111 N1
b0000000000000000000000000000000000000000000000000000000000111110 N2
#63
b0000000000000000000000000000000000000000000000000000000001000000 N1
b0000000000000000000000000000000000000000000000000000000000111111 N2
#64
b0000000000000000000000000000000000000000000000000000000001000001 N1
b0000000000000000000000000000000000000000000000000000000001000000 N2
#65
b0000000000000000000000000000000000000000000000000000000001000010 N1
b0000000000000000000000000000000000000000000000000000000001000001 N2
#66
b0000000000000000000000000000000000000000000000000000000001000011 N1
b0000000000000000000000000000000000000000000000000000000001000010 N2
#67
b0000000000000000000000000000000000000000000000000000000001000100 N1
b0000000000000000000000000000000000000000000000000000000001000011 N2
#68
b0000000000000000000000000000000000000000000000000000000001000101 N1
b0000000000000000000000000000000000000000000000000000000001000100 N2
#69
b0000000000000000000000000000000000000000000000000000000001000110 N1
b0000000000000000000000000000000000000000000000000000000001000101 N2
#70
b0000000000000000000000000000000000000000000000000000000001000111 N1
b0000000000000000000000000000000000000000000000000000000001000110 N2
#71
b0000000000000000000000000000000000000000000000000000000001001000 N1
b0000000000000000000000000000000000000000000000000000000001000111 N2
#72
b0000000000000000000000000000000000000000000000000000000001001001 N1
b0000000000000000000000000000000000000000000000000000000001001000 N2
#73
b0000000000000000000000000000000000000000000000000000000001001010 N1
b0000000000000000000000000000000000000000000000000000000001001001 N2
#74
b0000000000000000000000000000000000000000000000000000000001001011 N1
b0000000000000000000000000000000000000000000000000000000001001010 N2
#75
b0000000000000000000000000000000000000000000000000000000001001100 N1
b0000000000000000000000000000000000000000000000000000000001001011 N2
#76
b0000000000000000000000000000000000000000000000000000000001001101 N1
b0000000000000000000000000000000000000000000000000000000001001100 N2
#77
b0000000000000000000000000000000000000000000000000000000001001110 N1
b0000000000000000000000000000000000000000000000000000000001001101 N2
#78
b0000000000000000000000000000000000000000000000000000000001001111 N1
b0000000000000000000000000000000000000000000000000000000001001110 N2
#79
b0000000000000000000000000000000000000000000000000000000001010000 N1
b0000000000000000000000000000000000000000000000000000000001001111 N2
#80
b0000000000000000000000000000000000000000000000000000000001010001 N1
b0000000000000000000000000000000000000000000000000000000001010000 N2
#81
b0000000000000000000000000000000000000000000000000000000001010010 N1
b0000000000000000000000000000000000000000000000000000000001010001 N2
#82
b0000000000000000000000000000000000000000000000000000000001010011 N1
b0000000000000000000000000000000000000000000000000000000001010010 N2
#83
b0000000000000000000000000000000000000000000000000000000001010100 N1
b0000000000000000000000000000000000000000000000000000000001010011 N2
#84
b0000000000000000000000000000000000000000000000000000000001010101 N1
b0000000000000000000000000000000000000000000000000000000001010100 N2
#85
b0000000000000000000000000000000000000000000000000000000001010110 N1
b0000000000000000000000000000000000000000000000000000000001010101 N2
#86
b0000000000000000000000000000000000000000000000000000000001010111 N1
b0000000000000000000000000000000000000000000000000000000001010110 N2
#87
b0000000000000000000000000000000000000000000000000000000001011000 N1
b0000000000000000000000000000000000000000000000000000000001010111 N2
#88
b0000000000000000000000000000000000000000000000000000000001011001 N1
b0000000000000000000000000000000000000000000000000000000001011000 N2
#89
b0000000000000000000000000000000000000000000000000000000001011010 N1
b0000000000000000000000000000000000000000000000000000000001011001 N2
#90
b0000000000000000000000000000000000000000000000000000000001011011 N1
b0000000000000000000000000000000000000000000000000000000001011010 N2
#91
b0000000000000000000000000000000000000000000000000000000001011100 N1
b0000000000000000000000000000000000000000000000000000000001011011 N2
#92
b0000000000000000000000000000000000000000000000000000000001011101 N1
b0000000000000000000000000000000000000000000000000000000001011100 N2
#93
b0000000000000000000000000000000000000000000000000000000001011110 N1
b0000000000000000000000000000000000000000000000000000000001011101 N2
#94
b0000000000000000000000000000000000000000000000000000000001011111 N1
b0000000000000000000000000000000000000000000000000000000001011110 N2
#95
b0000000000000000000000000000000000000000000000000000000001100000 N1
b0000000000000000000000000000000000000000000000000000000001011111 N2
#96
b0000000000000000000000000000000000000000000000000000000001100001 N1
b0000000000000000000000000000000000000000000000000000000001100000 N2
#97
b0000000000000000000000000000000000000000000000000000000001100010 N1
b0000000000000000000000000000000000000000000000000000000001100001 N2
#98
b0000000000000000000000000000000000000000000000000000000001100011 N1
b0000000000000000000000000000000000000000000000000000000001100010 N2
EOF

#include "harness.bash"
