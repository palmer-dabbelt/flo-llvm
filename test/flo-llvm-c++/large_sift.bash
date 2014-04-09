#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="ScaleSpaceExtrema"
ARGS="Random_16_2_3"

cat >>$TEST.tar.gz.base64 <<EOF
#include "large_sift-tar.bash"
EOF
cat $TEST.tar.gz.base64 | base64 --decode | gunzip | tar -x

sed 's/package SIFT//g' -i *.scala

sed 's/object SIFT/object ScaleSpaceExtrema/g' -i main.scala
cat main.scala >> ScaleSpaceExtrema.scala
rm main.scala

#include "harness.bash"
