#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val i = UInt(INPUT,  width = 48)
    val cat = UInt(OUTPUT, width = 64)
    val shuffle = UInt(OUTPUT, width = 64)
  }

  val I = List(33, 34, 35, 36, 37, 38,
               39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
               1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
               15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
               27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
               39, 40, 41, 42, 43, 44, 45, 46, 47, 48)

  def getBitsBE1(in: Bits, positions: List[Int]) = {
    Cat(positions.map{ x => in(in.getWidth - x) })
  }

  io.cat     := Cat(io.i, io.i)
  io.shuffle := getBitsBE1(io.i, I)
}

class tests(t: test) extends Tester(t) {
  for (i <- 0 until 48) {
    poke(t.io.i, BigInt(1) << i)
    step(1)
  }

  for (i <- 0 until 100) {
    poke(t.io.i, BigInt(48, rnd))
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
