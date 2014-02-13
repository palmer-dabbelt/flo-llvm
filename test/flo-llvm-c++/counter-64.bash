#include "tempdir.bash"

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

    for (int cycle = 0; cycle <= cycles; cycle++) {
        dut.clock_lo(cycle == 0);
        dut.clock_hi(cycle == 0);
        if (cycle > 0)
            dut.dump(vcd, cycle - 1);
    }

    fclose(vcd);

    return 0;
}
EOF

#include "harness.bash"
