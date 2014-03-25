#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val i = UInt(INPUT,  width = 3)
    val o = UInt(OUTPUT, width = 32)
  }

  val map = List(8792, 9872, 19823, 19082, 67219, 2097, 6738, 9876)
  val iter = map.iterator
  val mem = Vec.fill(8){ Bits(iter.next()) }

  io.o := mem(io.i)
}

class tests(t: test) extends Tester(t) {
  var cycle = 0
  do {
    poke(t.io.i, cycle % 8)
    step(1)

    cycle += 1
  } while (cycle < 1000)
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "chisel-jar.bash"
#include "harness.bash"
