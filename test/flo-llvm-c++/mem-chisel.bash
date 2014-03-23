#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val r = Bool(INPUT)
    val i = UInt(INPUT,  width = 8)
    val o = UInt(OUTPUT, width = 32)
  }

  val mem = Mem(UInt(width = 32), 256)

  val r = Reg(init = UInt(0, width = 32))
  when (io.r) { r := (r << UInt(5)) + r }
  when (io.i === UInt(0)) { r := UInt(5381) }

  io.o := r
  when (io.r)  { io.o := mem(io.i) }
  when (!io.r) { mem(io.i) := r    }
}

class tests(t: test) extends Tester(t) {
  var cycle = 0
  do {
    poke(t.io.i, cycle % 256)
    poke(t.io.r, 0)
    step(1)

    poke(t.io.i, cycle % 256)
    poke(t.io.r, 1)
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
