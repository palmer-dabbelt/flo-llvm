#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val lo = UInt(OUTPUT, width = 32)
    val hi = UInt(OUTPUT, width = 32)
    val o = Vec.fill(64){ UInt(OUTPUT, width = 1) }
  }

  val r_lo = Reg(init = UInt(5381, width = 32))
  val lo = UInt(width = 27); lo := r_lo
  r_lo := (lo << UInt(5)) + r_lo;
  io.lo := r_lo

  val r_hi = Reg(init = UInt(5381, width = 32))
  val hi = UInt(width = 27); hi := r_hi
  r_hi := (hi << UInt(5)) + r_hi + r_lo
  io.hi := r_hi

  val r = Cat(r_hi, r_lo)

  for (i <- 0 until 64) { io.o(i) := r >> UInt(i) }
}

class tests(t: test) extends Tester(t) {
  var cycle = 0
  do {
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
