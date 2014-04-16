#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val data = UInt(INPUT, width = 256)
    val offset = UInt(INPUT, width = 8)
    val bit = UInt(OUTPUT, width = 1)
  }

  io.bit := io.data(io.offset)
}

class tests(t: test) extends Tester(t) {
  for (i <- 0 until 256) {
    val data = BigInt(1) << i
    poke(t.io.data, data)
    poke(t.io.offset, 0)
    step(1)
    expect(t.io.bit, data & 1)
  }
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "harness.bash"
