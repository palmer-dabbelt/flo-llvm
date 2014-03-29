#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="DES"

cat >DES.scala <<EOF
import Chisel._
import scala.collection.mutable.ArrayBuffer

object DESConstants {

    val InitialKeySize = 64;

    val SubkeySize = 56;

    val BlockSize = 64;

    val NumRounds = 16;
      
    val IPL = List(58,50,42,34,26,18,10,2,
                   60,52,44,36,28,20,12,4,
                   62,54,46,38,30,22,14,6,
                   64,56,48,40,32,24,16,8);

    val IPR = List(57,49,41,33,25,17,9,1,
                   59,51,43,35,27,19,11,3,
                   61,53,45,37,29,21,13,5,
                   63,55,47,39,31,23,15,7);

    val FP = List(40,8,48,16,56,24,64,32,
                  39,7,47,15,55,23,63,31,
                  38,6,46,14,54,22,62,30,
                  37,5,45,13,53,21,61,29,
                  36,4,44,12,52,20,60,28,
                  35,3,43,11,51,19,59,27,
                  34,2,42,10,50,18,58,26,
                  33,1,41,9,49,17,57,25);

    val E = List(32,1,2,3,4,5,
                 4,5,6,7,8,9,
                 8,9,10,11,12,13,
                 12,13,14,15,16,17,
                 16,17,18,19,20,21,
                 20,21,22,23,24,25,
                 24,25,26,27,28,29,
                 28,29,30,31,32,1);


    val P = List(16,7,20,21,29,12,28,17,
                 1,15,23,26,5,18,31,10,
                 2,8,24,14,32,27,3,9,
                 19,13,30,6,22,11,4,25);

    val PC1L = List(57,49,41,33,25,17,9,
                    1,58,50,42,34,26,18,
                    10,2,59,51,43,35,27,
                    19,11,3,60,52,44,36);

    val PC1R = List(63,55,47,39,31,23,15,
                    7,62,54,46,38,30,22,
                    14,6,61,53,45,37,29,
                    21,13,5,28,20,12,4);

    val PC2 = List(14,17,11,24,1,5,3,28,
                   15,6,21,10,23,19,12,4,
                   26,8,16,7,27,20,13,2,
                   41,52,31,37,47,55,30,40,
                   51,45,33,48,44,49,39,56,
                   34,53,46,42,50,36,29,32);

    val RoundRotations = List(0,1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1);

    val SBoxMaps = List(

        List(14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7,
                         0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8,
                         4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0,
                         15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13),
    
    
        List(15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10,
                         3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5,
                         0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15,
                         13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9),
    
        List(10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8,
                         13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1,
                         13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7,
                         1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12),
    
        List(7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15,
                         13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9,
                         10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4,
                         3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14),
    
        List(2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9,
                         14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6,
                         4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14,
                         11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3),
    
        List(12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11,
                         10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8,
                         9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6,
                         4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13),
    
        List(4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1,
                         13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6,
                         1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2,
                         6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12),
    
        List(13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7,
                         1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2,
                         7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8,
                         2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11)

    );

}

import DESConstants._
import Utils._

class DESSBox(map: List[Int]) extends Module {
    val io = new Bundle {
        val in = Bits(INPUT, width = 6)
        val out = Bits(OUTPUT, width = 4)
    }
    val iter = map.iterator
    val idx = Cat(io.in(5), io.in(0), io.in(4, 1))
    val table = Vec.fill(64){ Bits(iter.next()) }
    io.out := table(idx)
}

class DESRound extends Bundle {
    val KeyRotationL = Bits(width = SubkeySize/2)
    val KeyRotationR = Bits(width = SubkeySize/2)
    val Subkey       = Bits(width = SubkeySize)
    val BlockL       = Bits(width = BlockSize/2)
    val BlockR       = Bits(width = BlockSize/2)
}

class DESIO extends Bundle {
    val key        = Bits(INPUT, width = InitialKeySize)
    val plaintext  = Bits(INPUT, width = BlockSize)
    val ciphertext = Bits(OUTPUT, width = BlockSize)
    val skdiag     = Bits(OUTPUT, width = InitialKeySize)
}

class DES extends Module {

    val io = new DESIO()
    val rounds = Vec.fill(NumRounds+1) { new DESRound() }
    val roundFunctions = ArrayBuffer.fill(NumRounds+1) { Module(new Feistel()) }

    // initial round half-blocks swapped to keep loop operations consistent
    rounds(0).KeyRotationL := getBitsBE1(io.key, PC1L)
    rounds(0).KeyRotationR := getBitsBE1(io.key, PC1R)
    rounds(0).BlockR       := getBitsBE1(io.plaintext, IPL)
    rounds(0).BlockL       := getBitsBE1(io.plaintext, IPR)

    for (i <- 1 until NumRounds+1) {
        rounds(i).KeyRotationL := rotateLeft(rounds(i-1).KeyRotationL, RoundRotations(i))
        rounds(i).KeyRotationR := rotateLeft(rounds(i-1).KeyRotationR, RoundRotations(i))
	rounds(i).Subkey       := getBitsBE1(Cat(rounds(i).KeyRotationL, rounds(i).KeyRotationR), PC2)
	roundFunctions(i).io.halfBlock := rounds(i-1).BlockL
	roundFunctions(i).io.subkey := rounds(i).Subkey
        rounds(i).BlockL    := roundFunctions(i).io.output ^ rounds(i-1).BlockR
        rounds(i).BlockR    := rounds(i-1).BlockL
    }
    io.skdiag := Cat(rounds(NumRounds).BlockL, rounds(NumRounds).BlockR)
    io.ciphertext := getBitsBE1(Cat(rounds(NumRounds).BlockL, rounds(NumRounds).BlockR), FP)
}

class DESTester(c: DES) extends Tester(c) {
  val plaintext = BigInt("0000000100100011010001010110011110001001101010111100110111101111", 2)
  val key = BigInt("0001001100110100010101110111100110011011101111001101111111110001", 2)
  val after16 = BigInt("0000101001001100110110011001010101000011010000100011001000110100", 2)
  val ciphertext = BigInt("1000010111101000000100110101010000001111000010101011010000000101", 2)

  poke(c.io.key, key)
  poke(c.io.plaintext, plaintext)
  step(1)
  expect(c.io.skdiag, after16)
  expect(c.io.ciphertext, ciphertext)


  // from the Handbook of Applied Cryptography
  val bookKey         = BigInt("0123456789ABCDEF", 16)
  val bookPlaintexts  = List(BigInt("4E6F772069732074", 16), BigInt("68652074696D6520", 16), BigInt("666F7220616C6C20", 16))
  val bookCiphertexts = List(BigInt("3FA40E8A984D4815", 16), BigInt("6A271787AB8883F9", 16), BigInt("893D51EC4B563B53", 16))

  poke(c.io.key, bookKey)
  for (i <- 0 until 3) {
    poke(c.io.plaintext, bookPlaintexts(i))
    step(1)
    expect(c.io.ciphertext, bookCiphertexts(i))
  }

  for (i <- 0 until 1000) {
    poke(c.io.key, rnd.nextInt(65535))
    poke(c.io.plaintext, rnd.nextInt(65535))
    step(1)
  }
}

class FeistelIO extends Bundle {
    val halfBlock = Bits(INPUT, width = BlockSize/2)
    val subkey    = Bits(INPUT, width = SubkeySize)
    val output    = Bits(OUTPUT, width = BlockSize/2)
}

class Feistel extends Module {
    val io = new FeistelIO()
    val expanded = getBitsBE1(io.halfBlock, E)
    val xored = expanded ^ io.subkey
    val iter = SBoxMaps.iterator
    val subs = ArrayBuffer.fill(8) { Module(new DESSBox(iter.next())) }
    for (i <- 0 until 8) { subs(i).io.in := xored(48 - (i*6), 42 - (i*6)) }
    val subbed = Cat(subs.map{ x => x.io.out })
    io.output := getBitsBE1(subbed, P)
}

class TestVecIO extends Bundle {
    val in  = Bits(INPUT, width = 28)
    val out = Bits(OUTPUT, width = 28)
}

class TestVec extends Module {

    val io = new TestVecIO()

    val v = Vec.fill(16) { Bits(width = 28) }

    v(0) := io.in(27,0)

    io.out := v(0)
}

class TestVecTester(c: TestVec) extends Tester(c) {

  def toBinDigits (bi: BigInt): String = { 
    if (bi == 0) "0" else toBinDigits (bi /2) + (bi % 2)
  }

  poke(c.io.in, BigInt(5))
  step(1)
  val out = peek(c.io.out)
  println(toBinDigits(out))
}

object Utils {
    def getBitsBE1(in: Bits, positions: List[Int]) = Cat(positions.map{ x => in(in.getWidth - x) })
    def rotateLeft(in: Bits, shamt: Int): Bits = {
        if (shamt > 0) {
            Cat(in(in.getWidth - shamt - 1, 0), in(in.getWidth - 1, in.getWidth - shamt))
        } else {
            in
        }
    }
}

object DES {
  def main(args: Array[String]): Unit = {
    chiselMainTest(args, () => Module(new DES())){ c => new DESTester(c) }
  }
}

EOF

#include "harness.bash"
