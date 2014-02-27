#!/bin/bash

set -x

# The path to the tutorial source code
TUTORIAL_PATH="$HOME/.local/src/chisel-tutorial"
TEST_PATH="$(pwd)/test/flo-llvm-c++"

# Here we attempt to match
cd "$TUTORIAL_PATH/examples"
find * -maxdepth 1 -iname "*.scala" | cut -d'.' -f 1 | while read f
do
    # Run every test in the tutorial to obtain results.  If the build
    # failed then don't include it in the list of tests that should be
    # run.  Note that this doesn't indicate a failure of the whole
    # script because some of these are just bogus.
    sbt "run $f --debug --genHarness --compile --test --backend c --vcd" \
        >& $f-c++.log || continue

    # Now we can start generating a test file that will actually run
    # these tests.
    test="$TEST_PATH"/tutgen_$f.bash
    echo '#include "tempdir.bash"' > $test

    # Dump the C++ support code as well
    echo "cat >harness.c++ <<EOF" >> $test
    cat $f-emulator.cpp \
        | sed "s/#include \"$f.h\"/ #include \"test.h++\"/g" \
        >> $test
    echo "EOF" >> $test

    # Make sure to copy over the relevant emulator.h.
    echo "cat >emulator.h <<EOF" >> $test
    cat emulator.h | sed "s/^#include/ #include/g" >> $test
    echo "EOF" >> $test

    # Also copy over the VCD file
    echo 'cat >gold.vcd <<"EOF"' >> $test
    cat $f.vcd >> $test
    echo "EOF" >> $test

    # Additionally, copy over input to the test harness -- this way we
    # can get exactly reproducable results.
    echo "cat >test.stdin <<EOF" >> $test
    cat $f.stdin >> $test
    echo "EOF" >> $test

    # Now that we're sure the test runs acceptably, produce a Flo file
    # that we can use for this project.  Note that this has to be done
    # AFTER the rest of the C++ code, as it appears that running with
    # the Flo backend breaks something in the generated test harness
    # code...
    sbt "run $f --debug --backend flo" \
        >& $f-flo.log

    # Dump the Flo file directly into the test
    echo "cat >test.flo <<EOF" >> $test
    cat $f.flo >> $test
    echo "EOF" >> $test

    # Make the VCD files agree with the other harness
    echo "ln -s $f.vcd test.vcd" >> $test

    # This special magic actually runs the resulting binary
    echo '#include "harness.bash"' >> $test

    echo "SUCCESS $f"
done
