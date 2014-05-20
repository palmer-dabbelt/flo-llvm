#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val i = UInt(INPUT,  width = 32)
    val o = UInt(OUTPUT, width = 32)
  }

  io.o := -io.i
}

class tests(t: test) extends Tester(t) {
  for (cycle <- 0 until 100) {
    val a = BigInt(32, rnd)
    poke(t.io.i, a)
    step(1)
  }
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "chisel-jar.bash"
#include "harness.bash"
