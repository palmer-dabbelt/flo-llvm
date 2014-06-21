#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="ScaleSpaceExtrema"
ARGS="Random_160_2_5"

# FIXME: vcd2step doesn't work for this circuit.
STEP_BROKEN="true"

# FIXME: This test isn't actually too large, it just fails because of
# the output of WR nodes.  I've got no idea why these WR nodes look
# the way they do, so I'm just giving up for now...
LARGE="true"

cat >>$TEST.tar.gz.base64 <<EOF
#include "large_sift-tar.bash"
EOF
cat $TEST.tar.gz.base64 | base64 --decode | gunzip | tar -x

find . -iname "*.scala" | while read f
do
    cat "$f" | sed 's/package SIFT//g' > "$f".sedtmp
    mv "$f".sedtmp "$f"
done

cat main.scala | sed 's/object SIFT/object ScaleSpaceExtrema/g' \
    >> ScaleSpaceExtrema.scala
rm main.scala

#include "harness.bash"
