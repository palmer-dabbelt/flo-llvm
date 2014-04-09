#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val o = UInt(OUTPUT, width = 32)
  }

  def mkcounter() = {
    val r = Reg(init = UInt(0, width = 32))
    r := r + UInt(1)
    r
  }

  io.o := mkcounter()
}

class tests(t: test) extends Tester(t) {
  for (cycle <- 1 until 10) {
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
