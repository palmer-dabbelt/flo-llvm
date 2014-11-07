#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  class IO extends Bundle {
    val i = UInt(INPUT, width=62);
    val o = UInt(OUTPUT, width=1);
  }
  val io = new IO();
  io.o := io.i.orR
}

class tests(t: test) extends Tester(t) {
  for (cycle <- 0 until 100) {
    val i = BigInt(62, rnd)
    poke(t.io.i, i)
    step(1)
  }
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "harness.bash"
