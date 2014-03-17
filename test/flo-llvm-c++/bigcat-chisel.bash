#include "tempdir.bash"
#include "chisel-jar.bash"

cat >test.scala <<EOF
import Chisel._

class test extends Module {
  val io = new Bundle {
    val o7 = UInt(OUTPUT, width = 256)
    val o9 = UInt(OUTPUT, width = 320)

    val oo9 = UInt(OUTPUT, width = 320)
  }

  val r0 = Reg(init = UInt(0, width = 32))
  val r1 = Reg(init = UInt(0, width = 32))
  val r2 = Reg(init = UInt(0, width = 32))
  val r3 = Reg(init = UInt(0, width = 32))
  val r4 = Reg(init = UInt(0, width = 32))
  val r5 = Reg(init = UInt(0, width = 32))
  val r6 = Reg(init = UInt(0, width = 32))
  val r7 = Reg(init = UInt(0, width = 32))
  val r8 = Reg(init = UInt(0, width = 32))
  val r9 = Reg(init = UInt(0, width = 32))

  r0 := r0 + UInt(1)
  r1 := r1 + UInt(2)
  r2 := r2 + UInt(3)
  r3 := r3 + UInt(4)
  r4 := r4 + UInt(5)
  r5 := r5 + UInt(6)
  r6 := r6 + UInt(7)
  r7 := r7 + UInt(8)
  r8 := r8 + UInt(9)
  r9 := r9 + UInt(10)

  val c1 = Cat(r1, r0)
  val c2 = Cat(r2, c1)
  val c3 = Cat(r3, c2)
  val c4 = Cat(r4, c3)
  val c5 = Cat(r5, c4)
  val c6 = Cat(r6, c5)
  val c7 = Cat(r7, c6)
  val c8 = Cat(r8, c7)
  val c9 = Cat(r9, c8)

  io.o7 := c7
  io.o9 := c9

  val cc1 = Cat(r1, r0)
  val cc2 = Cat(r3, r2)
  val cc3 = Cat(r5, r4)
  val cc4 = Cat(r7, r6)
  val cc5 = Cat(r9, r8)
  val cc6 = Cat(cc2, cc1)
  val cc7 = Cat(cc4, cc3)
  val cc8 = Cat(cc7, cc6)
  val cc9 = Cat(cc5, cc8)

  io.oo9 := cc9
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

#include "harness.bash"
