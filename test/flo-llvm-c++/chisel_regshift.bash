#include "tempdir.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val in = UInt(OUTPUT, width = 16)
    val out_const = UInt(OUTPUT, width = 32)
    val out_var   = UInt(OUTPUT, width = 32)
  }

  io.out_const := io.in << UInt(5)
  val in = UInt(width = 5); in := io.in
  io.out_var   := io.in << in
}

class tests(t: test) extends Tester(t) {
  var cycle = 0
  do {
    poke(t.io.in, rnd.nextInt(128))
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
