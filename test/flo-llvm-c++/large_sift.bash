#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="ScaleSpaceExtrema"
ARGS="Random_16_2_3"

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
