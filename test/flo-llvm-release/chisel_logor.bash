#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val i = UInt(INPUT, width = 8)
    val o = Bool(OUTPUT)
    val a = Bool(OUTPUT)
  }

  io.o := io.i.orR
  io.a := io.i.andR
}

class tests(t: test) extends Tester(t) {
  for (cycle <- 0 until 256) {
    val i = BigInt(cycle)
    poke(t.io.i, i)

    step(1)

    if (i == 0)
      expect(t.io.o, 0)
    else
      expect(t.io.o, 1)

    if (i == 255)
      expect(t.io.a, 1)
    else
      expect(t.io.a, 0)
  }

  for (cycle <- 0 until 8192) {
    val i = BigInt(8, rnd)
    poke(t.io.i, i)

    step(1)

    if (i == 0)
      expect(t.io.o, 0)
    else
      expect(t.io.o, 1)

    if (i == 255)
      expect(t.io.a, 1)
    else
      expect(t.io.a, 0)
  }
}

object test {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new test())) { t => new tests(t) }
  }
}
EOF

#include "harness.bash"
