cat >chisel.jar.gz.base64 <<EOF
#include "chisel-jar-gz.bash"
EOF

cat chisel.jar.gz.base64 | base64 --decode > chisel.jar.gz
gunzip chisel.jar.gz
