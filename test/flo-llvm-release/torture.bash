#include "tempdir.bash"

testname="$(basename "$(dirname "$0")")"
seed="$(echo "$testname" | cut -d- -f2)"

TEST="Torture"

flo-torture --seed $seed
cat Torture.flo
cat Torture.vcd
mv Torture.vcd gold.vcd

chisel-hdrtar > headers.tar
tar -xf headers.tar

#include "harness.bash"
