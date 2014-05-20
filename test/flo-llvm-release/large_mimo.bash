# Source From: https://github.com/simonscott/ee290c-project-mimo

#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="MatrixEngine"
ARGS="-params_24_12_4_4"
LARGE="true"

cat >>$TEST.tar.gz.base64 <<EOF
#include "large_mimo-tar.bash"
EOF
cat $TEST.tar.gz.base64 | base64 --decode | gunzip | tar -x

find . -iname "*.scala" | while read f
do
    cat "$f" | sed 's/package Work//g' > "$f".sedtmp
    mv "$f".sedtmp "$f"
done

# Much of this code is pulled from Work where main() resides for the
# actual code.
cat >>MatrixEngine.scala <<EOF
object MatrixEngine {
  def main(args: Array[String]): Unit = {
    // Parse parameters: set LMS params
    val param_str = """-params_(.*)_(.*)_(.*)_(.*)""".r.findFirstMatchIn(args(0))
    require(param_str.isDefined, "First argument must be -param_w_e_t_r")
    val params = new LMSParams(param_str.get.group(1).toInt,
                               param_str.get.group(2).toInt,
                               param_str.get.group(3).toInt,
                               param_str.get.group(4).toInt)

    chiselMainTest(args, () => Module(new MatrixEngine()(params))) {
      t => new MatrixEngineTests(t, params)
    }
  }
}
EOF

#include "harness.bash"
