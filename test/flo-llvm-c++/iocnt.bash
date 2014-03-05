#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val i = UInt(INPUT,  width = 8)
    val o = UInt(OUTPUT, width = 8)
  }

  val r = Reg(UInt(width = 8))
  r := io.i
  io.o := r
}

class tests(t: test) extends Tester(t) {
  var cycle = 0
  do {
    poke(t.io.i, cycle)
    step(1)
    cycle += 1
  } while (cycle < 10)
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "chisel-jar.bash"
#include "harness.bash"
