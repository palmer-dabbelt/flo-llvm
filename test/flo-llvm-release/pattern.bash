#include "tempdir.bash"

testname="$(basename "$(dirname "$0")")"
pattern="$(echo "$testname" | cut -d- -f2)"
args="$(echo "$testname" | cut -d- -f3-)"

TEST="Torture"

flo-patterns --show $pattern $args
cat Torture.flo
cat Torture.vcd
mv Torture.vcd gold.vcd

chisel-hdrtar > headers.tar
tar -xf headers.tar

#include "harness.bash"
