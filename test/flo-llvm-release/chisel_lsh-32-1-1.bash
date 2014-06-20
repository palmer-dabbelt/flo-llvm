#include "tempdir.bash"
#include "chisel-jar.bash"

# FIXME: This isn't _actually_ large, it's just that Chisel appears to
# do some crazy width inference for these sorts of nodes...
LARGE="true"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  class IO extends Bundle {
    val in0 = Bits(INPUT, width=32);
    val out0 = Bits(OUTPUT, width=1);
  }
  val io = new IO();
  val io_in0 = Bits(width = 32);
  io_in0 := io.in0;
  val Torture1 = Bits(width = 1);
  Torture1 := (UInt(io_in0) << UInt(1)).toBits;
  io.out0 := Torture1;
}

class tests(t: test) extends Tester(t) {
  for (cycle <- 0 until 100) {
    val i = BigInt(32, rnd)
    poke(t.io.in0, i)
    step(1)
    val o = 0
    expect(t.io.out0, o)
  }
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "harness.bash"
