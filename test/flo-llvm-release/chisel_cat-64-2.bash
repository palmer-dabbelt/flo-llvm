#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val l = Bits(INPUT,  width = 64)
    val r = Bits(INPUT,  width =  2)
    val o = Bits(OUTPUT, width = 66)
  }

  io.o := Cat(io.l, io.r)
}

class tests(t: test) extends Tester(t) {
  for (cycle <- 0 until 100) {
    val l = BigInt(64, rnd)
    val r = BigInt( 2, rnd)
    poke(t.io.l, l)
    poke(t.io.r, r)
    step(1)
    val o = (l << 2) | r
    expect(t.io.o, o)
  }
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "harness.bash"
