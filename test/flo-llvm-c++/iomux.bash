#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val i = Bool(INPUT)
    val o = UInt(OUTPUT, width = 2)
  }

  val r = Reg(init = UInt(0))
  r := UInt(0)
  when   (io.i) { r := UInt(1) }
  unless (io.i) { r := UInt(2) }

  io.o := r
}

class tests(t: test) extends Tester(t) {
  var cycle = 0
  do {
    poke(t.io.i, cycle % 2)
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
