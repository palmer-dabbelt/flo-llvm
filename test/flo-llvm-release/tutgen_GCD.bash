#include "tempdir.bash"
cat >harness.c++ <<EOF
 #include "test.h"

int main (int argc, char* argv[]) {
  GCD_t* module = new GCD_t();
  module->init();
  GCD_api_t* api = new GCD_api_t();
  api->init(module);
  FILE *f = fopen("./GCD.vcd", "w");
  FILE *tee = fopen("GCD.stdin", "w");
  module->set_dumpfile(f);
  api->set_teefile(tee);
  api->read_eval_print_loop();
  fclose(f);
  fclose(tee);
}
EOF
cat >emulator.h <<EOF
// metaheader for the Chisel emulator and API
 #include "emulator_mod.h"
 #include "emulator_api.h"
EOF
cat >emulator_mod.h <<EOF
// Header for Chisel emulator module
// defines the mod_t class as well as bit operation functions

#ifndef __IS_EMULATOR_MOD__
#define __IS_EMULATOR_MOD__

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wsign-compare"
#pragma GCC diagnostic ignored "-Wparentheses"
#pragma GCC diagnostic ignored "-Wreturn-type"
#pragma GCC diagnostic ignored "-Wchar-subscripts"
#pragma GCC diagnostic ignored "-Wtype-limits"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-variable"

 #include <assert.h>
 #include <inttypes.h>
 #include <stdio.h>
 #include <limits.h>
 #include <math.h>
 #include <vector>
 #include <stdarg.h>
 #include <string.h>
 #include <time.h>
 #include <string>
 #include <map>
 #include <stdlib.h>
 #include <iostream>
 #include <fstream>
 #include <stdexcept>

using namespace std;

typedef uint64_t val_t;
typedef int64_t sval_t;
typedef uint32_t half_val_t;
//typedef __uint128_t dub_val_t;
// typedef uint32_t val_t;
// typedef uint8_t val_t;

union flo2int_t {
  float  f;
  val_t  i;
};

inline float toFloat (val_t x) {
  flo2int_t f2i;
  f2i.i = x;
  return f2i.f;
}

inline val_t fromFloat (float x) {
  flo2int_t f2i;
  f2i.f = x;
  return f2i.i;
}

union dbl2int_t {
  double f;
  val_t  i;
};

inline double toDouble (val_t x) {
  dbl2int_t f2i;
  f2i.i = x;
  return f2i.f;
}

inline val_t fromDouble (double x) {
  dbl2int_t f2i;
  f2i.f = x;
  return f2i.i;
}


#define MASK(v, c) ((v) & -(val_t)(c))
#define TERNARY(c, t, f) ((f) ^ (((f) ^ (t)) & -(c)))
#ifndef MIN
#define MIN(a, b) TERNARY((a) < (b), (a), (b))
#endif
#ifndef MAX
#define MAX(a, b) TERNARY((a) > (b), (a), (b))
#endif
#define CLAMP(a, min, max) MAX(MIN(a, max), min)

template<uint32_t x, uint32_t shifted=0, bool sticky=false> struct CeilLog {
    static uint32_t const v = CeilLog<(x >> 1), shifted + 1, sticky | (x & 1)>::v;
};

template<uint32_t shifted, bool sticky> struct CeilLog<0, shifted, sticky> {
    static uint32_t const v = -1;
};

template<uint32_t shifted, bool sticky> struct CeilLog<1, shifted, sticky> {
    static uint32_t const v = sticky ? shifted + 1 : shifted;
};

inline val_t val_n_bits( void ) { return sizeof(val_t)*8; }
inline val_t val_all_ones( void ) { return ~((val_t)0); }
// const val_t val_ones_or_zeroes[2] = { 0L, val_all_ones() };
// inline val_t val_all_ones_or_zeroes( val_t bit ) { return val_ones_or_zeroes[bit]; }
inline val_t val_all_ones_or_zeroes( val_t bit ) {
  return (val_t) ((sval_t) ((sval_t) bit << (val_n_bits() - 1)) >> (val_n_bits() -1));
  }
inline val_t val_top_bit( val_t v ) { return (v >> (val_n_bits()-1)); }
#define val_n_words(n_bits) (1+((n_bits)-1)/(8*sizeof(val_t)))
#define val_n_half_words(n_bits) (1+((n_bits)-1)/(8*sizeof(half_val_t)))
inline val_t val_n_full_words( val_t n_bits ) { return n_bits / val_n_bits(); }
inline val_t val_n_word_bits( val_t n_bits ) { return n_bits % val_n_bits(); }
inline val_t val_n_half_bits( void ) { return sizeof(half_val_t)*8; }
inline val_t val_n_nibs( void ) { return val_n_bits()>>2; }
inline val_t val_half_mask( void ) { return (((val_t)1)<<(val_n_half_bits()))-1; }
inline val_t val_lo_half( val_t n_bits ) { return n_bits & val_half_mask(); }
inline val_t val_hi_half( val_t n_bits ) { return n_bits >> val_n_half_bits(); }
inline val_t val_n_rem_word_bits( val_t n_bits ) { return val_n_bits() - val_n_word_bits(n_bits); }
//inline val_t dub_val_lo_half( dub_val_t bits ) { return (val_t)bits; }
//inline val_t dub_val_hi_half( dub_val_t bits ) { return (val_t)(bits >> val_n_bits()); }


inline void  val_to_half_vals ( val_t *fvals, half_val_t *hvals, int nf ) {
  for (int i = 0; i < nf; i++) {
    hvals[i*2]   = val_lo_half(fvals[i]);
    hvals[i*2+1] = val_hi_half(fvals[i]);
  }
}
inline void  half_val_to_vals ( half_val_t *hvals, val_t *vals, int nf ) {
  for (int i = 0; i < nf; i++)
    vals[i] = ((val_t)hvals[i*2+1] << val_n_half_bits()) | hvals[i*2];
}

template <int w> class dat_t;
template <int w> class datz_t;

template <int w> int datz_eq(dat_t<w> d1, datz_t<w> d2);

template <int w> inline dat_t<w> DAT(val_t value) {
  dat_t<w> res(value);
  return res; }

template <int w> inline dat_t<w> DAT(val_t val1, val_t val0) {
  dat_t<w> res; res.values[0] = val0; res.values[1] = val1; return res;
}

const static char hex_digs[] =
  {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };

static void add_n (val_t d[], val_t s0[], val_t s1[], int nw, int nb) {
  val_t carry = 0;
  for (int i = 0; i < nw; i++) {
    d[i] = s0[i] + s1[i] + carry;
    carry = ((s0[i] + s1[i]) < s0[i]) || (d[i] < carry);
  }
}

static void neg_n (val_t d[], val_t s0[], int nw, int nb) {
  val_t borrow = 0;
  for (int i = 0; i < nw; i++) {
    d[i]  = -s0[i] - borrow;
    borrow = s0[i] || d[i];
  }
}

static void sub_n (val_t d[], val_t s0[], val_t s1[], int nw, int nb) {
  val_t borrow = 0;
  for (int i = 0; i < nw; i++) {
    d[i]  = s0[i] - s1[i] - borrow;
    borrow = (s0[i] < (s0[i] - s1[i])) || (s0[i] - s1[i]) < d[i];
  }
}

static void mul_n (val_t d[], val_t s0[], val_t s1[], int nbd, int nb0, int nb1) {
// Adapted from Hacker's Delight, from Knuth
#if BYTE_ORDER != LITTLE_ENDIAN
# error mul_n assumes a little-endian architecture
#endif
  for (int i = 0; i < val_n_words(nbd); i++)
    d[i] = 0;

  half_val_t* w = reinterpret_cast<half_val_t*>(d);
  half_val_t* u = reinterpret_cast<half_val_t*>(s0);
  half_val_t* v = reinterpret_cast<half_val_t*>(s1);
  int m = val_n_half_words(nb0), n = val_n_half_words(nb1), p = val_n_half_words(nbd);

  for (int j = 0; j < n; j++) {
    val_t k = 0;
    for (int i = 0; i < MIN(m, p-j); i++) {
      val_t t = (val_t)u[i]*v[j] + w[i+j] + k;
      w[i+j] = t;
      k = t >> val_n_half_bits();
    }
    if (j+m < p)
      w[j+m] = k;
  }
}

static void rsha_n (val_t d[], val_t s0[], int amount, int nw, int w) {

  int n_shift_bits     = amount % val_n_bits();
  int n_shift_words    = amount / val_n_bits();
  int n_rev_shift_bits = val_n_bits() - n_shift_bits;
  int is_zero_carry    = n_shift_bits == 0;
  int msb              = s0[nw-1] >> (w - nw*val_n_bits() - 1);
  val_t carry = 0;

  if (msb == 0)
    for (int i = 0; i < n_shift_words; i++) {
      d[nw-i-1] = 0;
    }

  for (int i = nw-1; i >= n_shift_words; i--) {
    val_t val = s0[i];
    d[i-n_shift_words] = val >> n_shift_bits | carry;
    carry              = is_zero_carry ? 0 : val << n_rev_shift_bits;
  }

  if (msb == 0) {
    return;
  }

  int boundary = (w - amount);

  for (int i = nw-1; i >= 0; i--) {
    int idx = i*val_n_bits();
    if (idx  > boundary) {
      d[i] = val_all_ones();
    } else {
      d[i] = d[i] | (val_all_ones() << (boundary - idx));
      d[nw-1] = d[nw-1] & (val_all_ones() >> ((nw-1)*val_n_bits() - w));
      return;
    }
  }
}

static void rsh_n (val_t d[], val_t s0[], int amount, int nw) {
  val_t carry = 0;
  int n_shift_bits     = amount % val_n_bits();
  int n_shift_words    = amount / val_n_bits();
  int n_rev_shift_bits = val_n_bits() - n_shift_bits;
  int is_zero_carry    = n_shift_bits == 0;
  for (int i = 0; i < n_shift_words; i++)
    d[nw-i-1] = 0;
  for (int i = nw-1; i >= n_shift_words; i--) {
    val_t val = s0[i];
    d[i-n_shift_words] = val >> n_shift_bits | carry;
    carry              = is_zero_carry ? 0 : val << n_rev_shift_bits;
  }
}

static void lsh_n (val_t d[], val_t s0[], int amount, int nwd, int nws) {
  val_t carry          = 0;
  int n_shift_bits     = amount % val_n_bits();
  int n_shift_words    = amount / val_n_bits();
  int n_rev_shift_bits = val_n_bits() - n_shift_bits;
  int is_zero_carry    = n_shift_bits == 0;
  for (int i = 0; i < n_shift_words; i++)
    d[i] = 0;
  for (int i = 0; i < (nws-n_shift_words); i++) {
    val_t val = s0[i];
    d[i+n_shift_words] = val << n_shift_bits | carry;
    carry              = is_zero_carry ? 0 : val >> n_rev_shift_bits;
  }
  for (int i = nws-n_shift_words; i < nwd; i++)
    d[i] = 0;
}

static inline val_t mask_val(int n) {
  val_t res = val_all_ones() >> (val_n_bits()-n);
  return res;
}

static void div_n (val_t d[], val_t s0[], val_t s1[], int nbd, int nb0, int nb1) {
  assert(MAX(nbd, MAX(nb0, nb1)) <= val_n_bits()); // TODO: generalize
  d[0] = s1[0] == 0 ? mask_val(nb0) : s0[0] / s1[0];
}

static inline void mask_n (val_t d[], int nw, int nb) {
  int n_full_words = val_n_full_words(nb);
  int n_word_bits  = val_n_word_bits(nb);
  for (int i = 0; i < n_full_words; i++)
    d[i] = val_all_ones();
  for (int i = n_full_words; i < nw; i++)
    d[i] = 0;
  if (n_word_bits > 0)
    d[n_full_words] = mask_val(n_word_bits);
}

static inline val_t log2_1 (val_t v) {
  val_t r;
  val_t shift;

  r     = (v > 0xFFFFFFFF) << 5; v >>= r;
  shift = (v > 0xFFFF    ) << 4; v >>= shift; r |= shift;
  shift = (v > 0xFF      ) << 3; v >>= shift; r |= shift;
  shift = (v > 0xF       ) << 2; v >>= shift; r |= shift;
  shift = (v > 0x3       ) << 1; v >>= shift; r |= shift;
  r    |= (v >> 1);
  return r;
}

#define ispow2(x) (((x) & ((x)-1)) == 0)
static inline val_t nextpow2_1(val_t x) {
  x--;
  x |= x >> 1;
  x |= x >> 2;
  x |= x >> 4;
  x |= x >> 8;
  x |= x >> 16;
  x |= x >> 32;
  x++;
  return x;
}

/*
#define __FLOAT_WORD_ORDER LITTLE_ENDIAN

static inline uint32_t log2_1_32 (uint32_t v) {
  union { uint32_t u[2]; double d; } t; // temp

  t.u[__FLOAT_WORD_ORDER==LITTLE_ENDIAN] = 0x43300000;
  t.u[__FLOAT_WORD_ORDER!=LITTLE_ENDIAN] = v;
  t.d -= 4503599627370496.0;
  return (t.u[__FLOAT_WORD_ORDER==LITTLE_ENDIAN] >> 20) - 0x3FF;
}

static inline val_t log2_1 (val_t v) {
  uint32_t r_lo = (uint32_t)v;
  uint32_t r_hi = (uint32_t)(v >> 32);
  return (((val_t)log2_1_32(r_hi)) << 32)|((val_t)log2_1_32(r_lo));
}
*/

/*
static inline val_t log2_1 (val_t v) {
  v |= (v >> 1);
  v |= (v >> 2);
  v |= (v >> 4);
  v |= (v >> 8);
  v |= (v >> 16);
  v |= (v >> 32);
  return ones64(v) - 1;
}
*/

/*
static inline val_t log2_1 (val_t v) {
  val_t res = 0;
  while (v >>= 1)
    res++;
  return res;
}
*/

static inline val_t log2_n (val_t s0[], int nw) {
  val_t off = (nw-1)*val_n_bits();
  for (int i = nw-1; i >= 0; i--) {
    val_t s0i = s0[i];
    if (s0i > 0) {
      val_t res = log2_1(s0i);
      return res + off;
    }
    off -= val_n_bits();
  }
  return 0;
}

template <int nw>
struct bit_word_funs {
  static void fill (val_t d[], val_t s0) {
    for (int i = 0; i < nw; i++)
      d[i] = s0;
  }
  static void fill_nb (val_t d[], val_t s0, int nb) {
    mask_n(d, nw, nb);
    for (int i = 0; i < nw; i++)
      d[i] = d[i] & s0;
    // printf("FILL-NB N\n");
  }
  static void copy (val_t d[], val_t s0[], int sww) {
    if (sww > nw) {
      for (int i = 0; i < nw; i++) {
        // printf("A I %d\n", i); fflush(stdout);
        d[i] = s0[i];
      }
    } else {
      for (int i = 0; i < sww; i++) {
        // printf("B I %d\n", i); fflush(stdout);
        d[i] = s0[i];
      }
      for (int i = sww; i < nw; i++) {
        // printf("C I %d\n", i); fflush(stdout);
        d[i] = 0;
      }
    }
  }
  static void mask (val_t d[], int nb) {
    mask_n(d, nw, nb);
  }
  static void add (val_t d[], val_t s0[], val_t s1[], int nb) {
    add_n(d, s0, s1, nw, nb);
  }
  static void neg (val_t d[], val_t s0[], int nb) {
    neg_n(d, s0, nw, nb);
  }
  static void sub (val_t d[], val_t s0[], val_t s1[], int nb) {
    sub_n(d, s0, s1, nw, nb);
  }
  static void mul (val_t d[], val_t s0[], val_t s1[], int nbd, int nb0, int nb1) {
    mul_n(d, s0, s1, nbd, nb0, nb1);
  }
  static void bit_xor (val_t d[], val_t s0[], val_t s1[]) {
    for (int i = 0; i < nw; i++)
      d[i] = s0[i] ^ s1[i];
  }
  static void bit_and (val_t d[], val_t s0[], val_t s1[]) {
    for (int i = 0; i < nw; i++)
      d[i] = s0[i] & s1[i];
  }
  static void bit_or (val_t d[], val_t s0[], val_t s1[]) {
    for (int i = 0; i < nw; i++)
      d[i] = s0[i] | s1[i];
  }
  static void bit_neg (val_t d[], val_t s0[], int nb) {
    val_t msk[nw];
    mask_n(msk, nw, nb);
    for (int i = 0; i < nw; i++)
      d[i] = ~s0[i] & msk[i];
  }
  static void ltu (val_t d[], val_t s0[], val_t s1[]) {
    val_t diff[nw];
    sub(diff, s0, s1, nw*val_n_bits());
    d[0] = val_top_bit(diff[nw-1]);
  }
  static void lt (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    if (msb_0 != msb_1) {
      d[0] = msb_0;
    } else {
      val_t diff[nw];
      sub(diff, s0, s1, nw*val_n_bits());
      d[0] = val_top_bit(diff[nw-1]);
    }
  }
  static void gtu (val_t d[], val_t s0[], val_t s1[]) {
    val_t diff[nw];
    sub(diff, s1, s0, nw*val_n_bits());
    d[0] = val_top_bit(diff[nw-1]);
  }
  static void gt (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    if (msb_0 != msb_1) {
      d[0] = msb_1;
    } else {
      val_t diff[nw];
      sub(diff, s1, s0, nw*val_n_bits());
      d[0] = val_top_bit(diff[nw-1]);
    }
  }
  static void lteu (val_t d[], val_t s0[], val_t s1[]) {
    val_t diff[nw];
    sub(diff, s1, s0, nw*val_n_bits());
    d[0] = !val_top_bit(diff[nw-1]);
  }
  static void lte (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    if (msb_0 != msb_1) {
      d[0] = msb_0;
    } else {
      val_t diff[nw];
      sub(diff, s1, s0, nw*val_n_bits());
      d[0] = !val_top_bit(diff[nw-1]);
    }
  }
  static void gteu (val_t d[], val_t s0[], val_t s1[]) {
    val_t diff[nw];
    sub(diff, s0, s1, nw*val_n_bits());
    d[0] = !val_top_bit(diff[nw-1]);
  }
  static void gte (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - (nw-1)*val_n_bits() - 1)) & 0x1;
    if (msb_0 != msb_1) {
      d[0] = msb_1;
    } else {
      val_t diff[nw];
      sub(diff, s0, s1, nw*val_n_bits());
      d[0] = !val_top_bit(diff[nw-1]);
    }
  }
  static void eq (val_t d[], val_t s0[], val_t s1[]) {
    for (int i = 0; i < nw; i++) {
      if (s0[i] != s1[i]) {
        d[0] = 0;
        return;
      }
    }
    d[0] = 1;
  }
  static void neq (val_t d[], val_t s0[], val_t s1[]) {
    eq(d, s0, s1);
    d[0] = !d[0];
  }
  static void rsha (val_t d[], val_t s0[], int amount, int w) {
    rsha_n(d, s0, amount, nw, w);
  }
  static void rsh (val_t d[], val_t s0[], int amount) {
    rsh_n(d, s0, amount, nw);
  }
  static void lsh (val_t d[], val_t s0[], int amount) {
    lsh_n(d, s0, amount, nw, nw);
  }
  static void extract (val_t d[], val_t s0[], int e, int s, int nb) {
    // TODO: FINISH THIS
    const int bw = e-s+1;
    val_t msk[nw];
    mask_n(msk, nw, nb);
    if (s == 0) {
      // printf("EXT E %d S %d NW %d NB %d: ", e, s, nw, nb);
      for (int i = 0; i < nw; i++) {
        d[i] = s0[i] & msk[i];
        // printf("%d:%llx ", i, d[i]);
      }
    } else {
      rsh_n(d, s0, s, nw);
      // printf("EXT E %d S %d NW %d NB %d: ", e, s, nw, nb);
      for (int i = 0; i < nw; i++) {
        // printf("I%d:R%llx:M%llx:", i, d[i], msk[i]);
        d[i] = d[i] & msk[i];
        // printf("D%llx ", d[i]);
      }
    }
    // printf("\n");
  }

  static void inject (val_t d[], val_t s0[], int e, int s) {
    // Opposite of extract: Assign s0 to a subfield of d.
    const int bw = e-s+1;
    val_t msk[nw];
    val_t msk_lsh[nw];
    val_t s0_lsh[nw];
    mask_n(msk, nw, bw);
    lsh_n(msk_lsh, msk, s, nw, nw);
    lsh_n(s0_lsh, s0, s, nw, nw);
    for (int i = 0; i < nw; i++) {
      d[i] = (d[i] & ~msk_lsh[i]) | (s0_lsh[i] & msk_lsh[i]);
    }
  }

  static void set (val_t d[], val_t s0[]) {
    for (int i = 0; i < nw; i++)
      d[i] = s0[i];
  }
  static void log2 (val_t d[], val_t s0[]) {
    d[0] = log2_n(s0, nw);
  }
};

template <>
struct bit_word_funs<1> {
  static void fill (val_t d[], val_t s0) {
    d[0] = s0;
  }
  static void fill_nb (val_t d[], val_t s0, int nb) {
    d[0] = mask_val(nb) & s0;
  }
  static void copy (val_t d[], val_t s0[], int sww) {
    d[0] = s0[0];
  }
  static void mask (val_t d[], int nb) {
    d[0] = mask_val(nb);
  }
  static void add (val_t d[], val_t s0[], val_t s1[], int nb) {
    d[0] = (s0[0] + s1[0]) & mask_val(nb);
  }
  static void sub (val_t d[], val_t s0[], val_t s1[], int nb) {
    d[0] = (s0[0] - s1[0]) & mask_val(nb);
  }
  static void neg (val_t d[], val_t s0[], int nb) {
    d[0] = (- s0[0]) & mask_val(nb);
  }
  static void mul (val_t d[], val_t s0[], val_t s1[], int nbd, int nb0, int nb1) {
    if (nbd <= val_n_bits())
      d[0] = (s0[0] * s1[0]) & mask_val(nbd);
    else
      mul_n(d, s0, s1, nbd, nb0, nb1);
  }
  static void ltu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] < s1[0]);
  }
  static void lt (val_t d[], val_t s0[], val_t s1[], int w) {
    sval_t a = s0[0] << (val_n_bits() - w);
    sval_t b = s1[0] << (val_n_bits() - w);
    d[0] = (a < b);
  }
  static void gtu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] > s1[0]);
  }
  static void gt (val_t d[], val_t s0[], val_t s1[], int w) {
    sval_t a = s0[0] << (val_n_bits() - w);
    sval_t b = s1[0] << (val_n_bits() - w);
    d[0] = (a > b);
  }
  static void lteu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] <= s1[0]);
  }
  static void lte (val_t d[], val_t s0[], val_t s1[], int w) {
    sval_t a = s0[0] << (val_n_bits() - w);
    sval_t b = s1[0] << (val_n_bits() - w);
    d[0] = (a <= b);
  }
  static void gteu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] >= s1[0]);
  }
  static void gte (val_t d[], val_t s0[], val_t s1[], int w) {
    sval_t a = s0[0] << (val_n_bits() - w);
    sval_t b = s1[0] << (val_n_bits() - w);
    d[0] = (a >= b);
  }
  static void bit_neg (val_t d[], val_t s0[], int nb) {
    d[0] = ~s0[0] & mask_val(nb);
  }
  static void bit_xor (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] ^ s1[0]);
  }
  static void bit_and (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] & s1[0]);
  }
  static void bit_or (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] | s1[0]);
  }
  static void eq (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] == s1[0]);
  }
  static void neq (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] != s1[0]);
  }
  static void lsh (val_t d[], val_t s0[], int amount) {
    d[0] = (s0[0] << amount);
  }
  static void rsh (val_t d[], val_t s0[], int amount) {
    d[0] = (s0[0] >> amount);
  }
  static void rsha (val_t d[], val_t s0[], int amount, int w) {
    d[0] = s0[0] << (val_n_bits() - w);
    d[0] = (sval_t(d[0]) >> (val_n_bits() - w + amount)) & mask_val(w);
  }
  static void extract (val_t d[], val_t s0[], int e, int s, int nb) {
    const int bw = e-s+1;
    d[0] = (s0[0] >> s) & mask_val(bw);
  }

  static void inject (val_t d[], val_t s0[], int e, int s) {
    // Opposite of extract: Assign s0 to a subfield of d.
    const int bw = e-s+1;
    val_t msk = mask_val(bw);
    d[0] = ((s0[0] & msk) << s) | (d[0] & ~(msk << s));
  }

  static void set (val_t d[], val_t s0[]) {
    d[0] = s0[0];
  }
  static void log2 (val_t d[], val_t s0[]) {
    d[0] = log2_1(s0[0]);
  }
};

template <>
struct bit_word_funs<2> {
  static void fill (val_t d[], val_t s0) {
    d[0] = s0;
    d[1] = s0;
  }
  static void fill_nb (val_t d[], val_t s0, int nb) {
    d[0] = s0;
    d[1] = mask_val(nb - val_n_bits()) & s0;
  }
  static void copy (val_t d[], val_t s0[], int sww) {
    d[0] = s0[0];
    d[1] = sww > 1 ? s0[1] : 0;
  }
  static void mask (val_t d[], int nb) {
    d[0] = val_all_ones();
    d[1] = mask_val(nb - val_n_bits());
  }
  static void add (val_t d[], val_t x[], val_t y[], int nb) {
    val_t x0     = x[0];
    val_t sum0   = x0 + y[0];
    val_t carry0 = (sum0 < x0);
    d[0]         = sum0;
    val_t sum1   = x[1] + y[1] + carry0;
    d[1]         = sum1;
  }
  static void sub (val_t d[], val_t s0[], val_t s1[], int nb) {
    val_t d0 = s0[0] - s1[0];
    d[1] = s0[1] - s1[1] - (s0[0] < d0);
    d[0] = d0;
  }
  static void neg (val_t d[], val_t s0[], int nb) {
    val_t d0 = -s0[0];
    d[1] = -s0[1] - (s0[0] != 0);
    d[0] = d0;
  }
  static void mul (val_t d[], val_t s0[], val_t s1[], int nbd, int nb0, int nb1) {
    mul_n(d, s0, s1, nbd, nb0, nb1);
  }
  static void ltu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[1] < s1[1]) | (s0[1] == s1[1] & s0[0] < s1[0]));
  }
  static void lt (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - val_n_bits() - 1)) & 0x1;
    int cond  = msb_0 ^ msb_1;
    d[0] = (cond && msb_0)
        || (!cond && ((s0[1] < s1[1]) | (s0[1] == s1[1] & s0[0] < s1[0])));
  }
  static void gtu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[1] > s1[1]) | (s0[1] == s1[1] & s0[0] > s1[0]));
  }
  static void gt (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - val_n_bits() - 1)) & 0x1;
    int cond = msb_0 ^ msb_1;
    d[0] = (cond && msb_1)
        || (!cond && ((s0[1] > s1[1]) | (s0[1] == s1[1] & s0[0] > s1[0])));
  }
  static void lteu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[1] < s1[1]) | (s0[1] == s1[1] & s0[0] <= s1[0]));
  }
  static void lte (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - val_n_bits() - 1)) & 0x1;
    int cond = msb_0 ^ msb_1;
    d[0] = (cond && msb_0)
        || (!cond && ((s0[1] < s1[1]) | (s0[1] == s1[1] & s0[0] <= s1[0])));
  }
  static void gteu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[1] > s1[1]) | (s0[1] == s1[1] & s0[0] >= s1[0]));
  }
  static void gte (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - val_n_bits() - 1)) & 0x1;
    int cond = msb_0 ^ msb_1;
    d[0] = (cond && msb_1)
        || (!cond && ((s0[1] > s1[1]) | (s0[1] == s1[1] & s0[0] >= s1[0])));
  }
  static void bit_xor (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] ^ s1[0]);
    d[1] = (s0[1] ^ s1[1]);
  }
  static void bit_and (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] & s1[0]);
    d[1] = (s0[1] & s1[1]);
  }
  static void bit_or (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] | s1[0]);
    d[1] = (s0[1] | s1[1]);
  }
  static void bit_neg (val_t d[], val_t s0[], int nb) {
    d[0] = ~s0[0];
    d[1] = ~s0[1] & mask_val(nb - val_n_bits());
  }
  static void eq (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] == s1[0]) & (s0[1] == s1[1]);
  }
  static void neq (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] != s1[0]) | (s0[1] != s1[1]);
  }
  static void extract (val_t d[], val_t s0[], int e, int s, int nb) {
    val_t msk[2];
    const int bw = e-s+1;
    mask_n(msk, 2, bw);
    if (s == 0) {
      d[0] = s0[0] & msk[0];
      d[1] = s0[1] & msk[1];
    } else {
      rsh(d, s0, s);
      d[0] = d[0] & msk[0];
      d[1] = d[1] & msk[1];
    }
  }

  static void inject (val_t d[], val_t s0[], int e, int s) {
    // Opposite of extract: Assign s0 to a subfield of d.
    const int bw = e-s+1;
    val_t msk[2];
    val_t msk_lsh[2];
    val_t s0_lsh[2];
    mask_n(msk, 2, bw);
    lsh_n(msk_lsh, msk, s, 2, 2);
    lsh_n(s0_lsh, s0, s, 2, 2);
    d[0] = (d[0] & ~msk_lsh[0]) | (s0_lsh[0] & msk_lsh[0]);
    d[1] = (d[1] & ~msk_lsh[1]) | (s0_lsh[1] & msk_lsh[1]);
  }

  static void rsha (val_t d[], val_t s0[], int amount, int w) {
    sval_t hi = s0[1] << (2*val_n_bits() - w);
    if (amount >= val_n_bits()) {
      d[0] = hi >> (amount - w + val_n_bits());
      d[1] = hi >> (val_n_bits() - 1);
      d[1] = d[1] >> (2*val_n_bits() - w);
    } else if (amount == 0) {
      d[0] = s0[0];
      d[1] = s0[1];
    } else {
      int s = 2*val_n_bits() - w + amount;
      d[0] = s0[0] >> amount;
      d[0] = d[0] | ((hi >> (2*val_n_bits() - w)) << (val_n_bits() - amount));
      d[1] = hi >> (s >= val_n_bits() ? val_n_bits()-1 : s);
      d[1] = d[1] & mask_val(w - val_n_bits());
    }
  }
  static void rsh (val_t d[], val_t s0[], int amount) {
    if (amount >= val_n_bits()) {
      d[1] = 0;
      d[0] = s0[1] >> (amount - val_n_bits());
    } else if (amount == 0) {
      d[0] = s0[0];
      d[1] = s0[1];
    } else {
      d[1] = s0[1] >> amount;
      d[0] = (s0[1] << (val_n_bits() - amount)) | (s0[0] >> amount);
    }
  }
  static void lsh (val_t d[], val_t s0[], int amount) {
    if (amount == 0)
    {
      d[1] = s0[1];
      d[0] = s0[0];
    } else if (amount >= val_n_bits()) {
      d[1] = s0[0] << (amount - val_n_bits());
      d[0] = 0;
    } else {
      d[1] = (s0[1] << amount) | (s0[0] >> (val_n_bits() - amount));
      d[0] = (s0[0] << amount);
    }
  }
  static void set (val_t d[], val_t s0[]) {
    d[0] = s0[0];
    d[1] = s0[1];
  }
  static void log2 (val_t d[], val_t s0[]) {
    val_t s01 = s0[1];
    if (s01 > 0)
      d[0] = log2_1(s01) + val_n_bits();
    else
      d[0] = log2_1(s0[0]);
    // d[0] = log2_n(s0, 2);
  }
};
template <>
struct bit_word_funs<3> {
  static void fill (val_t d[], val_t s0) {
    d[0] = s0;
    d[1] = s0;
    d[2] = s0;
  }
  static void fill_nb (val_t d[], val_t s0, int nb) {
    d[0] = s0;
    d[1] = s0;
    d[2] = mask_val(nb - 2*val_n_bits()) & s0;
  }
  static void copy (val_t d[], val_t s0[], int sww) {
    d[0] = s0[0];
    d[1] = sww > 1 ? s0[1] : 0;
    d[2] = sww > 2 ? s0[2] : 0;
  }
  static void mask (val_t d[], int nb) {
    d[0] = val_all_ones();
    d[1] = val_all_ones();
    d[2] = mask_val(nb - 2*val_n_bits());
  }
  static void add (val_t d[], val_t s0[], val_t s1[], int nb) {
    add_n(d, s0, s1, 3, nb);
  }
  static void sub (val_t d[], val_t s0[], val_t s1[], int nb) {
    sub_n(d, s0, s1, 3, nb);
  }
  static void neg (val_t d[], val_t s0[], int nb) {
    neg_n(d, s0, 3, nb);
  }
  static void mul (val_t d[], val_t s0[], val_t s1[], int nbd, int nb0, int nb1) {
    mul_n(d, s0, s1, nbd, nb0, nb1);
  }
  static void ltu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[2] < s1[2]) | ((s0[2] == s1[2]) & ((s0[1] < s1[1]) | ((s0[1] == s1[1]) & (s0[0] < s1[0])))));
  }
  static void lt (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int cond  = msb_0 ^ msb_1;
    d[0] = (cond && msb_0)
        || (!cond && (((s0[2] < s1[2]) | ((s0[2] == s1[2]) & ((s0[1] < s1[1]) | ((s0[1] == s1[1]) & (s0[0] < s1[0])))))));
  }
  static void gtu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[2] > s1[2]) | ((s0[2] == s1[2]) & ((s0[1] > s1[1]) | ((s0[1] == s1[1]) & (s0[0] > s1[0])))));
  }
  static void gt (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int cond  = msb_0 ^ msb_1;
    d[0] = (cond && msb_1)
        || (!cond && ((s0[2] > s1[2]) | ((s0[2] == s1[2]) & ((s0[1] > s1[1]) | ((s0[1] == s1[1]) & (s0[0] > s1[0]))))));
  }
  static void lteu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[2] < s1[2]) | ((s0[2] == s1[2]) & ((s0[1] < s1[1]) | ((s0[1] == s1[1]) & (s0[0] <= s1[0])))));
  }
  static void lte (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int cond  = msb_0 ^ msb_1;
    d[0] = (cond && msb_0)
        || (!cond && ((s0[2] < s1[2]) | ((s0[2] == s1[2]) & ((s0[1] < s1[1]) | ((s0[1] == s1[1]) & (s0[0] <= s1[0]))))));
  }
  static void gteu (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = ((s0[2] > s1[2]) | ((s0[2] == s1[2]) & ((s0[1] > s1[1]) | ((s0[1] == s1[1]) & (s0[0] >= s1[0])))));
  }
  static void gte (val_t d[], val_t s0[], val_t s1[], int w) {
    int msb_0 = (s0[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int msb_1 = (s1[1] >> (w - 2*val_n_bits() - 1)) & 0x1;
    int cond  = msb_0 ^ msb_1;
    d[0] = (cond && msb_1)
        || (!cond && ((s0[2] > s1[2]) | ((s0[2] == s1[2]) & ((s0[1] > s1[1]) | ((s0[1] == s1[1]) & (s0[0] >= s1[0]))))));
  }
  static void bit_xor (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] ^ s1[0]);
    d[1] = (s0[1] ^ s1[1]);
    d[2] = (s0[2] ^ s1[2]);
  }
  static void bit_and (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] & s1[0]);
    d[1] = (s0[1] & s1[1]);
    d[2] = (s0[2] & s1[2]);
  }
  static void bit_or (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] | s1[0]);
    d[1] = (s0[1] | s1[1]);
    d[2] = (s0[2] | s1[2]);
  }
  static void bit_neg (val_t d[], val_t s0[], int nb) {
    d[0] = ~s0[0];
    d[1] = ~s0[1];
    d[2] = ~s0[2] & mask_val(nb - 2*val_n_bits());
  }
  static void eq (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] == s1[0]) & (s0[1] == s1[1]) & (s0[2] == s1[2]);
  }
  static void neq (val_t d[], val_t s0[], val_t s1[]) {
    d[0] = (s0[0] != s1[0]) | (s0[1] != s1[1]) | (s0[2] != s1[2]);
  }
  static void extract (val_t d[], val_t s0[], int e, int s, int nb) {
    val_t msk[3];
    const int bw = e-s+1;
    mask_n(msk, 3, bw);
    if (s == 0) {
      d[0] = s0[0] & msk[0];
      d[1] = s0[1] & msk[1];
      d[2] = s0[2] & msk[2];
    } else {
      rsh(d, s0, s);
      d[0] = d[0] & msk[0];
      d[1] = d[1] & msk[1];
      d[2] = d[2] & msk[2];
    }
  }

  static void inject (val_t d[], val_t s0[], int e, int s) {
    const int bw = e-s+1;
    val_t msk[3];
    val_t msk_lsh[3];
    val_t s0_lsh[3];
    mask_n(msk, 3, bw);
    lsh_n(msk_lsh, msk, s, 3, 3);
    lsh_n(s0_lsh, s0, s, 3, 3);
    d[0] = (d[0] & ~msk_lsh[0]) | (s0_lsh[0] & msk_lsh[0]);
    d[1] = (d[1] & ~msk_lsh[1]) | (s0_lsh[1] & msk_lsh[1]);
    d[2] = (d[2] & ~msk_lsh[2]) | (s0_lsh[2] & msk_lsh[2]);
  }

  static void rsha (val_t d[], val_t s0[], int amount, int w) {
    rsha_n(d, s0, amount, 3, w);
  }
  static void rsh (val_t d[], val_t s0[], int amount) {
    rsh_n(d, s0, amount, 3);
  }
  static void lsh (val_t d[], val_t s0[], int amount) {
    lsh_n(d, s0, amount, 3, 3);
  }
  static void log2 (val_t d[], val_t s0[]) {
    d[0] = log2_n(s0, 3);
  }
  static void set (val_t d[], val_t s0[]) {
    d[0] = s0[0];
    d[1] = s0[1];
    d[2] = s0[2];
  }
};

static val_t rand_val_seed = time(NULL) | 1;
static val_t rand_val()
{
  val_t x = rand_val_seed;
  rand_val_seed = x>>1 | (x>>0^x>>60^x>>61^x>>63)<<63;
  return x;
}

template <int w>
class dat_t {
 public:
  const static int n_words = ((w - 1) / 64) + 1;
  // const static int n_words = (w >> CeilLog<sizeof(val_t)*8>::v) + 1;
  val_t values[n_words];
  inline int width ( void ) { return w; }
  inline int n_words_of ( void ) { return n_words; }
  inline bool to_bool ( void ) { return lo_word() != 0; }
  inline val_t lo_word ( void ) { return values[0]; }
  inline unsigned long to_ulong ( void ) { return (unsigned long)lo_word(); }

  std::string to_str () {
    std::string rres, res;
    int nn = (int)ceilf(w / 4.0);
    for (int i = 0; i < n_words; i++) {
      int n_nibs = nn < val_n_nibs() ? nn : val_n_nibs();
      for (int j = 0; j < n_nibs; j++) {
        uint8_t nib = (values[i] >> (j*4))&0xf;
        rres.push_back(hex_digs[nib]);
      }
      nn -= val_n_bits()/4;
    }
    res.push_back('0');
    res.push_back('x');
    for (int i = 0; i < rres.size(); i++)
      res.push_back(rres[rres.size()-i-1]);
    return res;
  }
  void randomize() {
    for (int i = 0; i < n_words; i++)
      values[i] = rand_val();
    if (val_n_word_bits(w))
      values[n_words-1] &= mask_val(val_n_word_bits(w));
  }
  static dat_t<w> rand() {
    dat_t<w> r;
    r.randomize();
    return r;
  }
  inline dat_t<w> () {
  }
  template <int sw>
  inline dat_t<w> (const dat_t<sw>& src) {
    bit_word_funs<n_words>::copy(values, (val_t*)src.values, src.n_words);
    if (sw != w && val_n_word_bits(w))
      values[n_words-1] &= mask_val(val_n_word_bits(w));
  }
  inline dat_t<w> (const dat_t<w>& src) {
    bit_word_funs<n_words>::set(values, (val_t*)src.values);
  }
  inline dat_t<w> (val_t val) {
    values[0] = val;
    int sww = n_words;
    for (int i = 1; i < sww; i++)
      values[i] = 0;
  }
  template <int sw>
  dat_t<w> mask(dat_t<sw> fill, int n) {
    dat_t<w> res;
    bit_word_funs<n_words>::mask(res.values, n);
    return res;
  }
  template <int dw>
  dat_t<dw> mask(int n) {
    dat_t<dw> res;
    return res.mask(*this, n);
  }
  template <int n>
  inline dat_t<n> mask(void) {
    dat_t<n> res = mask<n>(n);
    return res;
  }
  dat_t<w> operator + ( dat_t<w> o ) {
    dat_t<w> res;
    bit_word_funs<n_words>::add(res.values, values, o.values, w);
    return res;
  }
  dat_t<w> operator - ( dat_t<w> o ) {
    dat_t<w> res;
    bit_word_funs<n_words>::sub(res.values, values, o.values, w);
    return res;
  }
  dat_t<w> operator - ( ) {
    return ~(*this) + DAT<w>(1);
  }
  dat_t<w+w> operator * ( dat_t<w> o ) {
    dat_t<w+w> res;
    bit_word_funs<n_words>::mul(res.values, values, o.values, w+w, w, w);
    return res;
  }
  dat_t<w+w> fix_times_fix( dat_t<w> o ) {
    // TODO: CLEANUP AND ADD DIFFERENT WIDTHS FOR EACH OPERAND
    if (n_words == 1 && ((w + w) <= val_n_bits())) {
      val_t res = (val_t)(((sval_t)(values[0])) * ((sval_t)(o.values[0])));
      return DAT<w+w>(res & mask_val(w+w));
    } else {
      val_t sgn_a = msb();
      dat_t<w> abs_a = sgn_a ? -(*this) : (*this);
      val_t sgn_b = o.msb();
      dat_t<w> abs_b = sgn_b ? -o : o;
      dat_t<w+w> res;
      bit_word_funs<n_words>::mul(res.values, abs_a.values, abs_b.values, w+w, w, w);
      return (sgn_a ^ sgn_b) ? -res : res;
    }
  }
  dat_t<w> operator / ( dat_t<w> o ) {
    dat_t<w> res;
    div_n(res.values, values, o.values, w, w, w);
    return res;
  }
  dat_t<w> operator % ( dat_t<w> o ) {
    return *this - *this / o * o;
  }
  dat_t<w+w> ufix_times_fix( dat_t<w> o ) {
    // TODO: CLEANUP AND ADD DIFFERENT WIDTHS FOR EACH OPERAND
    if (n_words == 1 && ((w + w) <= val_n_bits())) {
      val_t res = (val_t)(values[0] * ((sval_t)(o.values[0])));
      return DAT<w+w>(res & mask_val(w+w));
    } else {
      dat_t<w> abs_a = (*this);
      val_t sgn_b = o.msb();
      dat_t<w> abs_b = sgn_b ? -o : o;
      dat_t<w+w> res;
      bit_word_funs<n_words>::mul(res.values, abs_a.values, abs_b.values, w+w, w, w);
      return sgn_b ? -res : res;
    }
  }
  dat_t<w+w> fix_times_ufix( dat_t<w> o ) {
    // TODO: CLEANUP AND ADD DIFFERENT WIDTHS FOR EACH OPERAND
    if (n_words == 1 && ((w + w) <= val_n_bits())) {
      val_t res = (val_t)(((sval_t)(values[0])) * o.values[0]);
      return DAT<w+w>(res & mask_val(w+w));
    } else {
      val_t sgn_a = msb();
      dat_t<w> abs_a = sgn_a ? -(*this) : (*this);
      dat_t<w> abs_b = o;
      dat_t<w+w> res;
      bit_word_funs<n_words>::mul(res.values, abs_a.values, abs_b.values, w+w, w, w);
      return sgn_a ? -res : res;
    }
  }
  dat_t<1> operator < ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::ltu(res.values, values, o.values);
    return res;
  }
  dat_t<1> operator > ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::gtu(res.values, values, o.values);
    return res;
  }
  dat_t<1> operator >= ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::gteu(res.values, values, o.values);
    return res;
  }
  dat_t<1> operator <= ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::lteu(res.values, values, o.values);
    return res;
  }
  inline dat_t<1> gt ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::gt(res.values, values, o.values, w);
    return res;
  }
  inline dat_t<1> gte ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::gte(res.values, values, o.values, w);
    return res;
  }
  inline dat_t<1> lt ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::lt(res.values, values, o.values, w);
    return res;
  }
  inline dat_t<1> lte ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::lte(res.values, values, o.values, w);
    return res;
  }
  dat_t<w> operator ^ ( dat_t<w> o ) {
    dat_t<w> res;
    bit_word_funs<n_words>::bit_xor(res.values, values, o.values);
    return res;
  }
  dat_t<w> operator & ( dat_t<w> o ) {
    dat_t<w> res;
    bit_word_funs<n_words>::bit_and(res.values, values, o.values);
    return res;
  }
  dat_t<w> operator | ( dat_t<w> o ) {
    dat_t<w> res;
    bit_word_funs<n_words>::bit_or(res.values, values, o.values);
    return res;
  }
  dat_t<w> operator ~ ( void ) {
    dat_t<w> res;
    bit_word_funs<n_words>::bit_neg(res.values, values, w);
    return res;
  }
  inline dat_t<1> operator ! ( void ) {
    return DAT<1>(!lo_word());
  }
  dat_t<1> operator && ( dat_t<1> o ) {
    return DAT<1>(lo_word() & o.lo_word());
  }
  dat_t<1> operator || ( dat_t<1> o ) {
    return DAT<1>(lo_word() | o.lo_word());
  }
  dat_t<1> operator == ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::eq(res.values, values, o.values);
    return res;
  }
  dat_t<1> operator == ( datz_t<w> o ) {
    return o == *this;
  }
  dat_t<1> operator != ( dat_t<w> o ) {
    dat_t<1> res;
    bit_word_funs<n_words>::neq(res.values, values, o.values);
    return res;
  }
  dat_t<w> operator << ( int amount ) {
    dat_t<w> res;
    bit_word_funs<n_words>::lsh(res.values, values, amount);
    return res;
  }
  inline dat_t<w> operator << ( dat_t<w> o ) {
    return *this << o.lo_word();
  }
  dat_t<w> operator >> ( int amount ) {
    dat_t<w> res;
    bit_word_funs<n_words>::rsh(res.values, values, amount);
    return res;
  }
  inline dat_t<w> operator >> ( dat_t<w> o ) {
    return *this >> o.lo_word();
  }
  dat_t<w> rsha ( dat_t<w> o) {
    dat_t<w> res;
    int amount = o.lo_word();
    bit_word_funs<n_words>::rsha(res.values, values, amount, w);
    return res;
  }
  dat_t<w>& operator = ( dat_t<w> o ) {
    bit_word_funs<n_words>::set(values, o.values);
    return *this;
  }
  dat_t<w> fill_bit( val_t bit ) {
    dat_t<w> res;
    val_t word = 0L - bit;
    bit_word_funs<n_words>::fill_nb(res.values, word, w);
    return res;
  }
  // TODO: SPEED THIS UP
  dat_t<w> fill_byte( val_t byte, int nb, int n ) {
    dat_t<w> res;
    bit_word_funs<n_words>::fill(res.values, 0L);
    for (size_t i = 0; i < n; i++)
      res = (res << nb) | byte;
    return res;
  }
  template <int dw, int n>
  dat_t<dw> fill( void ) {
    // TODO: GET RID OF IF'S
    dat_t<dw> res;
    if (w == 1) {
      return res.fill_bit(lo_word());
    } else {
      return res.fill_byte(lo_word(), w, n);
    }
  }
  template <int dw, int nw>
  dat_t<dw> fill( dat_t<nw> n ) {
    // TODO: GET RID OF IF'S
    dat_t<dw> res;
    if (w == 1) {
      return res.fill_bit(lo_word()&1);
    } else {
      return res.fill_byte(lo_word(), w, n);
    }
  }
  template <int dw>
  dat_t<dw> extract() {
    dat_t<dw> res;
    int i;
    for (i = 0; i < val_n_full_words(dw); i++)
      res.values[i] = values[i];
    if (val_n_word_bits(dw))
      res.values[i] = values[i] & mask_val(val_n_word_bits(dw));
    return res;
  }
  template <int dw>
  dat_t<dw> extract(val_t e, val_t s) {
    dat_t<w> x = (*this >> s);
    return x.extract<dw>();
  }
  template <int dw, int iwe, int iws>
  inline dat_t<dw> extract(dat_t<iwe> e, dat_t<iws> s) {
    return extract<dw>(e.lo_word(), s.lo_word());
  }

  template <int sw>
  dat_t<w> inject(dat_t<sw> src, val_t e, val_t s) {
    // Modify this.values in place.
    dat_t<w> inject_src(src); // Enlarged if needed to match inject_dst
    bit_word_funs<n_words>::inject(values, inject_src.values, e, s);
    return *this;
  }

  template <int sw, int iwe, int iws>
  inline dat_t<w> inject(dat_t<sw> src, dat_t<iwe> e, dat_t<iws> s) {
    return inject<w>(src, e.lo_word(), s.lo_word());
  }


  template <int dw>
  inline dat_t<dw> log2() {
    dat_t<dw> res;
    bit_word_funs<n_words>::log2(res.values, values);
    return res;
  }
  inline dat_t<1> bit(val_t b) {
    int n_full_words = val_n_full_words(b);
    int n_word_bits  = val_n_word_bits(b);
    return DAT<1>((values[n_full_words] >> n_word_bits)&1);
  }
  inline val_t msb() {
    int n_full_words = val_n_full_words(w-1);
    int n_word_bits  = val_n_word_bits(w-1);
    return (values[n_full_words] >> n_word_bits)&1;
  }
  template <int iw>
  inline dat_t<1> bit(dat_t<iw> b) {
    return bit(b.lo_word());
  }
};

template <int w>
std::string dat_to_str(const dat_t<w>& x) {
  char s[w];
  s[dat_to_str(s, x)] = 0;
  return s;
}

static __inline__ int n_digits(int w, int base) {
  return (int)ceil(log(2)/log(base)*w);
}

template <int w>
int dat_to_str(char* s, dat_t<w> x, int base = 16, char pad = '0') {
  int n_digs = n_digits(w, base);
  int j = n_digs-1, digit;

  do {
    if (ispow2(base)) {
      digit = x.lo_word() & (base-1);
      x = x >> log2_1(base);
    } else {
      digit = (x % base).lo_word();
      x = x / base;
    }
    s[j] = (digit >= 10 ? 'a'-10 : '0') + digit;
  } while (--j >= 0 && (x != 0).to_bool());

  for ( ; j >= 0; j--)
    s[j] = pad;

  return n_digs;
}

static __inline__ int dat_to_str(char* s, val_t x, int base = 16, char pad = '0') {
  return dat_to_str<sizeof(val_t)*8>(s, dat_t<sizeof(val_t)*8>(x), base, pad);
}

template <int w>
int fix_to_str(char* s, dat_t<w> x, int base = 16, char pad = '0') {
  bool neg = x.bit(w-1).to_bool();
  s[0] = neg;
  int len = dat_to_str<w>(s+1, neg ? -x : x, base, pad);
  return len+1;
}

static __inline__ int fix_to_str(char* s, val_t x, int base = 16, char pad = '0') {
  return fix_to_str(s, dat_t<sizeof(val_t)*8>(x), base, pad);
}

static __inline__ int flo_digits(int m, int e) {
  return 2 + n_digits(m, 10) + 2 + n_digits(e, 10);
}

template <int w>
int flo_to_str(char* s, dat_t<w> x, char pad = ' ') {
  char buf[1000];
  int n_digs = (w == 32) ? flo_digits(32, 8) : flo_digits(52, 11);
  double val = (w == 32) ? toFloat(x.values[0]) : toDouble(x.values[0]);
  // sprintf(buf, "%d %d%*e", w, n_digs, n_digs, val);
  sprintf(buf, "%*e", n_digs, val);
  assert(strlen(buf) <= n_digs);
  for (int i = 0; i < n_digs; i++)
    s[i] = (i < strlen(buf)) ? buf[i] : pad;
  s[n_digs] = 0;
  // printf("N-DIGS = %d BUF %lu PAD %lu\n", n_digs, strlen(buf), n_digs-strlen(buf));
  // return strlen(buf);
  return n_digs;
}

template <int w>
int dat_as_str(char* s, const dat_t<w>& x) {
  int i, j;
  for (i = 0, j = (w/8-1)*8; i < w/8; i++, j -= 8) {
    char ch = x.values[j/val_n_bits()] >> (j % val_n_bits());
    if (ch == 0) break;
    s[i] = ch;
  }
  for ( ; i < w/8; i++)
    s[i] = ' ';
  return w/8;
}

static __inline__ int dat_as_str(char* s, val_t x) {
  return dat_as_str(s, dat_t<sizeof(val_t)*8>(x));
}

#if __cplusplus >= 201103L
static void __attribute__((unused)) dat_format(char* s, const char* fmt)
{
  for (char c; (c = *fmt); fmt++) {
    if (c == '%' && *++fmt != '%')
      abort();
    *s++ = c;
  }
}

template <typename T, typename... Args>
static void dat_format(char* s, const char* fmt, T value, Args... args)
{
  while (*fmt) {
    if (*fmt == '%') {
      switch(fmt[1]) {
        case 'e': s += flo_to_str(s, value, ' '); break;
        case 'h': s += dat_to_str(s, value, 16, '0'); break;
        case 'b': s += dat_to_str(s, value, 2, '0'); break;
        case 'd': s += dat_to_str(s, value, 10, ' '); break;
        case 's': s += dat_as_str(s, value); break;
        case '%': *s++ = '%'; break;
        default: abort();
      }
      return dat_format(s, fmt + 2, args...);
    } else {
      *s++ = *fmt++;
    }
  }
  abort();
}

template <int w, typename... Args>
static dat_t<w> dat_format(const char* fmt, Args... args)
{
#if BYTE_ORDER != LITTLE_ENDIAN
# error dat_format assumes a little-endian architecture
#endif
  char str[w/8+1];
  dat_format(str, fmt, args...);

  dat_t<w> res;
  res.values[res.n_words-1] = 0;
  for (int i = 0; i < w/8; i++)
    ((char*)res.values)[w/8-1-i] = str[i];
  return res;
}

template <int w, typename... Args>
static ssize_t dat_fprintf(FILE* f, const char* fmt, Args... args)
{
  char str[w/8+1];
  dat_format(str, fmt, args...);
  return fwrite(str, 1, w/8, f);
}
#endif /* C++11 */

template <int w, int sw> inline dat_t<w> DAT(dat_t<sw> dat) {
  dat_t<w> res(dat);
  return res;
}

template <int w> inline dat_t<w> LIT(val_t value) {
  return DAT<w>(value);
}

template <int w>
inline dat_t<w> mux ( dat_t<1> t, dat_t<w> c, dat_t<w> a ) {
  dat_t<w> mask;
  bit_word_funs<val_n_words(w)>::fill(mask.values, -t.lo_word());
  return a ^ ((a ^ c) & mask);
}

template <int w>
class datz_t : public dat_t<w> {
 public:
  dat_t<w> mask;
  inline dat_t<1> operator == ( dat_t<w> o ) {
    dat_t<w> masked = (o & mask);
    return (o & mask) == (dat_t<w>)*this;
  }
};

template <int w> datz_t<w> inline LITZ(val_t value, val_t mask) {
  datz_t<w> res; res.mask.values[0] = mask; res.values[0] = value; return res;
}

template < int w, int w1, int w2 >
inline dat_t<w> cat(dat_t<w1> d1, dat_t<w2> d2) {
  if (w <= val_n_bits() && w1 + w2 == w)
    return DAT<w>(d1.values[0] << (w2 & (val_n_bits()-1)) | d2.values[0]);
  return DAT<w>((DAT<w>(d1) << w2) | DAT<w>(d2));
}

template < int w1 >
inline dat_t<1> reduction_and(dat_t<w1> d) {
  return DAT<1>(d == ~DAT<w1>(0));
}

template < int w1 >
inline dat_t<1> reduction_or(dat_t<w1> d) {
  return DAT<1>(d != DAT<w1>(0));
}

// I am O(n) where n is number of bits in val_t. Future optimization would be log(n).
template < int w1 >
inline dat_t<1> reduction_xor(dat_t<w1> d) {
  dat_t<1> res = DAT<1>(0);
  val_t word = d.values[0];

  for (int i = 1; i < d.n_words_of(); i++)
      word ^= d.values[i];
  for (int i = 0; i < sizeof(val_t)*8; i++) {
      res = res ^ DAT<1>(word & 1);
      word = word >> 1;
  }

  return res;
}

template <int w, int d>
class mem_t {
 public:
  dat_t<w> contents[d];

  int width() {
    return w;
  }
  int length() {
    return d;
  }

  template <int iw>
  dat_t<w> get (dat_t<iw> idx) {
    return get(idx.lo_word() & (nextpow2_1(d)-1));
  }
  dat_t<w> get (val_t idx) {
    if (!ispow2(d) && idx >= d)
      return dat_t<w>::rand();
    return contents[idx];
  }
  val_t get (val_t idx, int word) {
    if (!ispow2(d) && idx >= d)
      return rand_val() & (word == val_n_words(w) && val_n_word_bits(w) ? mask_val(w) : -1L);
    return contents[idx].values[word];
  }

  template <int iw>
  void put (dat_t<iw> idx, dat_t<w> val) {
    put(idx.lo_word(), val);
  }
  void put (val_t idx, dat_t<w> val) {
    if (ispow2(d) || idx < d)
      contents[idx] = val;
  }
  val_t put (val_t idx, int word, val_t val) {
    if (ispow2(d) || idx < d)
      contents[idx].values[word] = val;
  }

  void print ( void ) {
    for (int j = 0; j < d/4; j++) {
      for (int i = 0; i < 4; i++) {
        int idx = j*4+i;
        printf("|%2d: %16llx| ", idx, contents[idx].lo_word());
      }
      printf("\n");
    }
  }
  mem_t<w,d> () {
    for (int i = 0; i < d; i++)
      contents[i] = DAT<w>(0);
  }
  void randomize() {
    for (int i = 0; i < d; i++)
      contents[i].randomize();
  }
  size_t read_hex(const char *hexFileName) {
    ifstream ifp(hexFileName);
    if (ifp.fail()) {
      printf("[error] Unable to open hex data file %s\n", hexFileName);
      return -1;
    }
    std::string hex_line;
    dat_t<w> hex_dat;
    for (int addr = 0; addr < d && !ifp.eof();) {
      getline(ifp, hex_line);
      if (dat_from_hex(hex_line, hex_dat) > 0) {
	contents[addr++] = hex_dat;
      }
    }
    ifp.close();
    return 0;
  }
};

static int  char_to_hex[] = {
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,
  -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 };

#define TO_CSTR(d) (d.to_str().c_str())

template <int w>
void str_to_dat(std::string str, dat_t<w>& res) {
  val_t word_accum = 0;
  int digit_val, digit, w_index, bit;
  for (digit = str.size()-1, w_index = 0, bit = 0; digit >= 0 && w_index < res.n_words; digit--) {
    digit_val = char_to_hex[str[digit]];
    if (digit_val >= 0) {
      word_accum |= ((val_t)digit_val) << bit;
      bit += 4;
      if (bit == 64) {
	res.values[w_index] = word_accum;
	word_accum          = 0L;
	bit                 = 0;
	w_index++;
      }
    }
  }
  if (bit != 0) {
    res.values[w_index] = word_accum;
    ++w_index;
  }
  for( ; w_index < res.n_words; ++w_index ) {
      res.values[w_index] = 0;
  }
  assert( res.n_words == w_index );
}

// dat_from_hex: Read a hex value from a std::string into a given dat_t variable.
// Author: B. Richards, for parsing data formatted for Verilog $readmemh
// Arguments:
//   hex_line  A string containing hex numbers with embedded x, _ characters
//   res       A dat_t object to fill in with a return value
//   offset    Starting index in hex_line
// Return value:
//   Success: returns next character offset
//   Fail:    0
template <int w>
size_t dat_from_hex(std::string hex_line, dat_t<w>& res, size_t offset = 0) {
  size_t first_digit, last_digit, comment;

  // Scan for the hex data bounds.
  comment = hex_line.find_first_of("/", offset);
  first_digit = hex_line.find_first_of("0123456789abcdefABCDEF", offset);
  if (first_digit == std::string::npos) return 0;
  if (comment != std::string::npos && comment < first_digit) return 0;
  last_digit = hex_line.find_first_not_of("0123456789abcdefABCDEF_xX", first_digit);
  if (last_digit == std::string::npos) {
    last_digit = hex_line.length() - 1;
  } else {
    last_digit--;
  }

  // Convert the hex data to a dat_t, from right to left.
  int digit_val;
  val_t word_accum = 0;
  int digit, w_index, bit;
  for (digit = last_digit, w_index = 0, bit = 0; digit >= (int)first_digit && w_index < res.n_words; digit--) {
    digit_val = char_to_hex[hex_line[digit]];
    if (digit_val >= 0) {
      word_accum |= ((val_t)digit_val) << bit;
      bit += 4;
      if (bit == 64) {
	res.values[w_index] = word_accum;
	word_accum = 0L;
	bit = 0;
	w_index++;
      }
    }
  }
  if (bit != 0) {
    res.values[w_index] = word_accum;
  }
  // Return a pointer to the character after the converted value.
  return last_digit + 1;
}

template <int w>
void dat_dump (FILE* file, dat_t<w> val, const char* name) {
  int namelen = strlen(name), pos = 0;
  char str[1 + w + 1 + namelen + 1 + 1];

  str[pos++] = 'b';
  for (int j = 0, wl = w; j < (w+8*sizeof(val_t)-1)/(8*sizeof(val_t)); j++)
    for (int i = 0; i < val_n_bits() && wl; i++)
      str[pos + --wl] = (val.values[j] >> i) & 1 ? '1' : '0';
  pos += w;
  str[pos++] = ' ';
  memcpy(str + pos, name, namelen); pos += namelen;
  str[pos++] = '\n';
  str[pos] = 0;

  fputs(str, file);
}

inline std::string read_tok(FILE* f) {
  std::string res;
  bool is_skipping = true;
  for (;;) {
    char c = fgetc(f);
    if (feof(f))
      return res;
    if (is_skipping) {
      if (char_to_hex[c] != -1) {
        res.push_back(c);
        is_skipping = false;
      }
    } else {
      if (char_to_hex[c] == -1) {
        ungetc(c, f);
        return res;
      }
      res.push_back(c);
    }
  }
}

template <int w, int d>
void dat_dump (FILE* file, mem_t<w,d> val, std::string name) {
}

template <int w, int d> mem_t<w,d> MEM( void );

class mod_t {
 public:
	mod_t():
	  dumpfile(NULL)
    {}
  std::vector< mod_t* > children;
  virtual void init ( bool rand_init=false ) { };
  virtual void clock_lo ( dat_t<1> reset ) { };
  virtual void clock_hi ( dat_t<1> reset ) { };
  virtual int  clock ( dat_t<1> reset ) { };
  virtual void setClocks ( std::vector< int >& periods ) { };

  virtual void print ( FILE* f ) { };
  virtual void dump ( FILE* f, int t ) { };

  void set_dumpfile(FILE* f) {
	dumpfile = f;
  }

  int timestep;

  void dump () {
    if (dumpfile != NULL) dump(dumpfile, timestep);
    timestep += 1;
  }

  int step (bool is_reset, int n) {
    int delta = 0;
    dat_t<1> reset = LIT<1>(is_reset);
    for (int i = 0; i < n; i++) {
      delta += clock(reset);
      dump();
    }
    return delta;
  }
 protected:
  FILE* dumpfile;
};

#define ASSERT(cond, msg) { \
  if (!(cond)) \
    throw std::runtime_error("Assertion failed: " msg); \
}

#pragma GCC diagnostic pop
#endif
EOF
cat >emulator_api.h <<EOF
// Header for Chisel emulator API
#ifndef __IS_EMULATOR_API__
#define __IS_EMULATOR_API__

 #include "emulator_mod.h"

 #include <string>
 #include <sstream>
 #include <map>

/**
 * Converts an integer to a std::string without needing additional libraries
 * or C++11.
 */
static std::string itos(int in) {
	std::stringstream out;
	out << in;
	return out.str();
}

/**
 * Copy one val_t array to another.
 * nb must be the exact number of bits the val_t represents.
 */
static void val_cpy(val_t* dst, val_t* src, int nb) {
    for (int i=0; i<val_n_words(nb); i++) {
        dst[i] = src[i];
    }
}

/**
 * Empty a val_t array (sets to zero).
 * nb must be the exact number of bits the val_t represents.
 */
static void val_empty(val_t* dst, int nb) {
    for (int i=0; i<val_n_words(nb); i++) {
        dst[i] = 0;
    }
}

/**
 * Set a val_t array to a integer number. Obviously, the maximum integer
 * is capped by the width of a single val_t element.
 * nb must be the exact number of bits the val_t represents.
 */
static void val_set(val_t* dst, val_t nb, val_t num) {
    val_empty(dst, nb);
    dst[0] = num;
}

/**
 * Sets a dat_t from a string, where the input radix is automatically determined
 * from the string (or defaults to 10).
 * Returns true on success.
 */
template <int w>
bool dat_from_str(std::string in, dat_t<w>& res, int pos = 0) {
    int radix = 10;

    if (!in.substr(pos, 1).compare("d")) {
        radix = 10;
        pos++;
    } else if (!in.substr(pos, 1).compare("h")
               || !in.substr(pos, 1).compare("x")) {
        radix = 16;
        pos++;
    } else if (!in.substr(pos, 2).compare("0h")
               || !in.substr(pos, 2).compare("0x")) {
        radix = 16;
        pos += 2;
    } else if (!in.substr(pos, 1).compare("b")) {
        radix = 2;
        pos++;
    } else if (!in.substr(pos, 2).compare("0b")) {
        radix = 2;
        pos += 2;
    }

    val_t radix_val = radix;
    val_t temp_prod[val_n_words(w)];
    val_t curr_base[val_n_words(w)];
    val_t temp_alias[val_n_words(w)];
    val_t *dest_val = res.values;
    val_set(curr_base, w, 1);
    val_empty(dest_val, w);

    for (int rpos=in.length()-1; rpos>=pos; rpos--) {
        char c = in[rpos];
        val_t c_val = 0;
        if (c == '_') {
            continue;
        }
        if (c >= '0' && c <= '9') {
            c_val = c - '0';
        } else if (c >= 'a' && c <= 'z') {
            c_val = c - 'a' + 10;
        } else if (c >= 'A' && c <= 'Z') {
            c_val = c - 'A' + 10;
        } else {
            std::cerr << "dat_from_str: Invalid character '" << c << "'" <<
            		std::endl;
            return false;
        }
        if (c_val > radix /* || c_val < 0 */) {
            std::cerr << "dat_from_str: Invalid character '" << c << "'" <<
            		std::endl;
            return false;
        }

        mul_n(temp_prod, curr_base, &c_val, w, w, val_n_bits());
        val_cpy(temp_alias, dest_val, w);   // copy to prevent aliasing on add
        add_n(dest_val, temp_alias, temp_prod, val_n_words(w), w);
        val_cpy(temp_alias, curr_base, w);
        mul_n(curr_base, temp_alias, &radix_val, w, w, val_n_bits());
    }
    return true;
}

// API base class, providing common functions
class api_base {
public:
	api_base(std::string new_name, std::string new_path) :
		name(new_name),
		path(new_path)
	{}
	// returns the fully qualified name of this object (path + dot + name)
	std::string get_pathname() {
		if (path.empty()) {
			return name;
		} else {
			return path + "." + name;
		}
	}
	// returns the short name of this object
	std::string get_name() {
		return name;
	}
	// returns the path of this object (without a trailing dot)
	std::string get_path() {
		return path;
	}
protected:
	std::string name;
	std::string path;
};

// API base (non width templated) class for API accessors to dat_t
class dat_api_base : public api_base {
public:
	dat_api_base(std::string new_name, std::string new_path) :
		api_base(new_name, new_path)
	{}
	// returns the value of this wire as a string, or empty string on failure
	virtual std::string get_value() = 0;
	// sets the value of this wire from a string, returning true on success
	virtual bool set_value(std::string value) = 0;
	// returns the bitwidth of this wire
	virtual std::string get_width() = 0;
};

// dat_api dummy class, does nothing except for return errors
// to be used when a real dat_api object can't be found
class dat_dummy : public dat_api_base {
public:
	dat_dummy() :
		dat_api_base("error", "")
	{}
	std::string get_value() {
		return "error";
	}

	bool set_value(std::string value) {
		return false;
	}

	std::string get_width() {
		return "error";
	}
};

template<int w> class dat_api : public dat_api_base {
public:
	dat_api(dat_t<w>* new_dat, std::string new_name, std::string new_path) :
		dat_api_base(new_name, new_path),
		dat_ptr(new_dat)
	{}

	std::string get_value() {
		return dat_ptr->to_str();
	}

	bool set_value(std::string value) {
		return dat_from_str<w>(value, *dat_ptr);
	}

	std::string get_width() {
		return itos(w);
	}

protected:
	dat_t<w>* dat_ptr;
};

// API base (non width/depth templated) class for API accessors to mem_t
class mem_api_base : public api_base {
public:
	mem_api_base(std::string new_name, std::string new_path) :
		api_base(new_name, new_path)
	{}
	// return the value of an element as a string, or empty string on failure
	virtual std::string get_element(std::string index) = 0;
	// sets the value of an element from a string, returning true on success
	virtual bool set_element(std::string index, std::string value) = 0;
	// returns the bitwidth of a memory element
	virtual std::string get_width() = 0;
	// returns the number of memory elements
	virtual std::string get_depth() = 0;
};

// mem_api dummy class, does nothing except for return errors
// to be used when a real mem_api object can't be found
class mem_dummy : public mem_api_base {
public:
	mem_dummy() :
		mem_api_base("error", "")
	{}
	string get_element(std::string index) {
		return "error";
	}

	bool set_element(std::string index, std::string value) {
		return false;
	}

	std::string get_width() {
		return "error";
	}

	std::string get_depth() {
		return "error";
	}
};

template<int w, int d> class mem_api : public mem_api_base {
public:
	mem_api(mem_t<w, d>* new_mem, std::string new_name, std::string new_path) :
		mem_api_base(new_name, new_path),
		mem_ptr(new_mem)
	{}

	string get_element(std::string index) {
		int index_int = atoi(index.c_str());
		return mem_ptr->contents[index_int].to_str();
	}

	bool set_element(std::string index, std::string value) {
		int index_int = atoi(index.c_str());
		return dat_from_str<w>(value, mem_ptr->contents[index_int]);
	}

	std::string get_width() {
		return itos(w);
	}

	std::string get_depth() {
		return itos(d);
	}

protected:
	mem_t<w, d>* mem_ptr;
};

class mod_api_t {
public:
	mod_api_t():
		teefile(NULL)
	{}

	void init(mod_t* new_module) {
		module = new_module;
		init_mapping_table();
	}

	void set_teefile(FILE* new_teefile) {
		teefile = new_teefile;
	}

	mod_t* get_module() {
		return module;
	}

	// API basic functions
	std::string get_host_name() {return "C++ Emulator API";}
	std::string get_api_version() {return "0";}
	std::string get_api_support() {return "PeekPoke Introspection";}

	// External access functions & helpers
	std::vector< std::string > tokenize(std::string str) {
	    std::vector< std::string > res;
	    int i = 0;
	    int c = ' ';
	    while ( i < str.size() ) {
	      while (isspace(c)) {
	        if (i >= str.size()) return res;
	        c = str[i++];
	      }
	      std::string s;
	      while (!isspace(c) && i < str.size()) {
	        s.push_back(c);
	        c = str[i++];
	      }
	      if (i >= str.size()) s.push_back(c);
	      if (s.size() > 0)
	        res.push_back(s);
	    }
	    return res;
	}

	// helper to verify command length, returning false and printing an error
	// to stderr if the length isn't in the specified range
	bool check_command_length(std::vector<std::string>& tokenized_command,
			int min_args, int max_args=-1) {
		if (tokenized_command.size() - 1 < min_args) {
			std::cerr << tokenized_command[0] << " expects at least " << min_args
					<< " args, got " << tokenized_command.size() - 1
					<< std::endl;
			return false;
		} else if (max_args >= 0 && tokenized_command.size() - 1 > max_args) {
			std::cerr << tokenized_command[0] << " expects at most " << max_args
					<< " args, got " << tokenized_command.size() - 1
					<< std::endl;
			return false;
		}
		return true;
	}

	std::string eval_command(string command) {
		std::vector<std::string> tokens = tokenize(command);
		if (tokens.size() == 0) {
			std::cerr << "Empty command: '" << command << "'" << std::endl;
			return "error";
		}
		if (tokens[0] == "get_host_name") {
			// IN:  get_host_name
			// OUT: API host's name
			if (!check_command_length(tokens, 0, 0)) { return "error"; }
			return get_host_name();
		} else if (tokens[0] == "get_api_version") {
			// IN:  get_api_version
			// OUT: API version supported by this host
			if (!check_command_length(tokens, 0, 0)) { return "error"; }
			return get_api_version();
		} else if (tokens[0] == "get_api_support") {
			// IN:  get_api_support
			// OUT: list of supported API features
			if (!check_command_length(tokens, 0, 0)) { return "error"; }
			return get_api_support();
		} else if (tokens[0] == "clock") {
			// IN:  clock <num_cycles>
			// OUT: actual number of cycles stepped
			if (!check_command_length(tokens, 1, 1)) { return "error"; }
			int cycles = atoi(tokens[1].c_str());
		    for (int i=0; i<cycles; i++) {
		    	module->clock_lo(dat_t<1>(0));
		    	module->clock_hi(dat_t<1>(0));
			module->dump();
		    }
		    module->clock_lo(dat_t<1>(0));
		    return itos(cycles);
		} else if (tokens[0] == "step") {
			// IN:  step <num_cycles>
			// OUT: actual number of cycles stepped
			if (!check_command_length(tokens, 1, 1)) { return "error"; }
			int n = atoi(tokens[1].c_str());
		    int ret = module->step(false, n);
		    return itos(ret);
		} else if (tokens[0] == "set_clocks") {
			// IN:  set_clocks
			// OUT: ???
			// I'm not really sure what this is supposed to do, but it was
			// in the old command API, so it's here now
	        std::vector< int > periods;
	        for (int i = 1; i < tokens.size(); i++) {
	          int period = atoi(tokens[i].c_str());
	          periods.push_back(period);
	        }
	        module->setClocks(periods);
	        return "ok";

		} else if (tokens[0] == "reset") {
			// IN:  reset <num_cycles>
			// OUT: actual number of cycles in reset
			if (!check_command_length(tokens, 0, 1)) { return "error"; }
			int cycles = 1;
			if (tokens.size() >= 2) {
				cycles = atoi(tokens[1].c_str());
			}
			for (int i=0; i<cycles; i++) {
			   	module->clock_lo(dat_t<1>(1));
			   	module->clock_hi(dat_t<1>(1));
		    }
		    module->clock_lo(dat_t<1>(0));
		    return itos(cycles);

		} else if (tokens[0] == "peek") {
			// IN:  peek <node_name> | peek <mem_name> <mem_index>
			// OUT: value
			if (!check_command_length(tokens, 1, 2)) { return "error"; }
			cerr << "peek is deprecated, use wire_peek or mem_peek" << std::endl;
			if (tokens.size() == 2) {
				return get_dat_by_name(tokens[1])->get_value();
			} else if (tokens.size() == 3) {
				return get_mem_by_name(tokens[1])->get_element(tokens[2]);
			}
		} else if (tokens[0] == "poke") {
			// IN:  poke <node_name> <value> | poke <mem_name> <mem_index> <value>
			// OUT: true (on success), false (on failure)
			if (!check_command_length(tokens, 2, 3)) { return ""; }
			cerr << "poke is deprecated, use wire_poke or mem_poke" << std::endl;
			bool success;
			if (tokens.size() == 3) {
				success = get_dat_by_name(tokens[1])->set_value(tokens[2]);
			} else if (tokens.size() == 4) {
				success = get_mem_by_name(tokens[1])->set_element(tokens[2], tokens[3]);
			}
			return success ? "true" : "false";

		} else if (tokens[0] == "wire_peek") {
			// IN:  wire_peek <node_name>
			// OUT: value
			if (!check_command_length(tokens, 1, 1)) { return "error"; }
			return get_dat_by_name(tokens[1])->get_value();
		} else if (tokens[0] == "wire_poke") {
			// IN:  wire_poke <node_name> <value>
			// OUT: true (on success), false (on failure)
			if (!check_command_length(tokens, 2, 2)) { return "error"; }
			bool success = get_dat_by_name(tokens[1])->set_value(tokens[2]);
			return success ? "true" : "false";
		} else if (tokens[0] == "mem_peek") {
			// IN:  mem_peek <mem_name> <mem_index>
			// OUT: value
			if (!check_command_length(tokens, 2, 2)) { return "error"; }
			return get_mem_by_name(tokens[1])->get_element(tokens[2]);
		} else if (tokens[0] == "mem_poke") {
			// IN:  mem_poke <mem_name> <mem_index> <value>
			// OUT: true (on success), false (on failure)
			if (!check_command_length(tokens, 3, 3)) { return "error"; }
			bool success = get_mem_by_name(tokens[1])->set_element(tokens[2], tokens[3]);
			return success ? "true" : "false";

		} else if (tokens[0] == "list_wires") {
			// IN:  list_wires
			// OUT: list of wires
			if (!check_command_length(tokens, 0, 0)) { return "error"; }
			std::string out = "";
			for (std::map<string, dat_api_base*>::iterator it = dat_table.begin(); it != dat_table.end(); it++) {
				out = out + it->second->get_pathname() + " ";
			}
			if (out.size() >= 1) {
				return out.substr(0, out.size() - 1);
			} else {
				return "";
			}

		} else if (tokens[0] == "list_mems") {
			// IN:  list_mems
			// OUT: list of memories
			if (!check_command_length(tokens, 0, 0)) { return "error"; }
			std::string out = "";
			for (std::map<string, mem_api_base*>::iterator it = mem_table.begin(); it != mem_table.end(); it++) {
				out = out + it->second->get_pathname() + " ";
			}
			if (out.size() >= 1) {
				return out.substr(0, out.size() - 1);
			} else {
				return "";
			}

		} else if (tokens[0] == "wire_width") {
			// IN:  wire_width <node>
			// OUT: bitwidth of wire
			if (!check_command_length(tokens, 1, 1)) { return "error"; }
			return get_dat_by_name(tokens[1])->get_width();
		} else if (tokens[0] == "mem_width") {
			// IN:  mem_width <node>
			// OUT: bitwidth of memory element
			if (!check_command_length(tokens, 1, 1)) { return "error"; }
			return get_mem_by_name(tokens[1])->get_width();
		} else if (tokens[0] == "mem_depth") {
			// IN:  mem_depth <node>
			// OUT: elements in memory
			if (!check_command_length(tokens, 1, 1)) { return "error"; }
			return get_mem_by_name(tokens[1])->get_depth();

		} else {
			std::cerr << "Unknown command: '" << tokens[0] << "'" << std::endl;
		}
		return "error";
	}

	void read_eval_print_loop() {
		while (true) {
		    std::string str_in;
		    getline(cin, str_in);
		    if (teefile != NULL) {
		        fprintf(teefile, "%s\n", str_in.c_str());
		        fflush(teefile);
		    }
		    if (str_in == "quit") {
		    	break;
		    } else {
		    	cout << eval_command(str_in) << std::endl;
		    }
		}
	}

protected:
	FILE* teefile;
	mod_t* module;

	// Mapping table functions
	virtual void init_mapping_table() = 0;

	dat_api_base* get_dat_by_name(std::string name) {
		if (dat_table.find(name) != dat_table.end()) {
			return dat_table[name];
		} else {
			std::cerr << "Unable to find dat '" << name << "'" << std::endl;
			return &this_dat_dummy;
		}
	}
	mem_api_base* get_mem_by_name(std::string name) {
		if (mem_table.find(name) != mem_table.end()) {
			return mem_table[name];
		} else {
			std::cerr << "Unable to find mem '" << name << "'" << std::endl;
			return &this_mem_dummy;
		}
	}

	std::map<string, dat_api_base*> dat_table;
	std::map<string, mem_api_base*> mem_table;
	dat_dummy this_dat_dummy;
	mem_dummy this_mem_dummy;
};

#endif
EOF
cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module GCD $end
$var wire 16 N0 io_z $end
$var wire 16 N1 io_a $end
$var wire 1 N2 io_e $end
$var wire 16 N3 x $end
$var wire 16 N4 io_b $end
$var wire 16 N5 y $end
$var wire 1 N6 io_v $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b0000000000000000 N0
b0000000001000000 N1
b1 N2
b0000000001000000 N3
b0000000000110000 N4
b0000000000110000 N5
b1 N6
#1
b0000000001000000 N0
b0 N2
b0000000000010000 N3
b0 N6
#2
b0000000000010000 N0
b0000000000100000 N5
#3
b0000000000010000 N5
#4
b0000000000000000 N5
#5
b1 N6
EOF
cat >test.stdin <<EOF
reset 5
wire_poke GCD.io_a 0x40
wire_poke GCD.io_b 0x30
wire_poke GCD.io_e 0x1
step 1
wire_poke GCD.io_a 0x40
wire_poke GCD.io_b 0x30
wire_poke GCD.io_e 0x0
step 1
wire_peek GCD.io_v
wire_poke GCD.io_a 0x40
wire_poke GCD.io_b 0x30
wire_poke GCD.io_e 0x0
step 1
wire_peek GCD.io_v
wire_poke GCD.io_a 0x40
wire_poke GCD.io_b 0x30
wire_poke GCD.io_e 0x0
step 1
wire_peek GCD.io_v
wire_poke GCD.io_a 0x40
wire_poke GCD.io_b 0x30
wire_poke GCD.io_e 0x0
step 1
wire_peek GCD.io_v
wire_poke GCD.io_a 0x40
wire_poke GCD.io_b 0x30
wire_poke GCD.io_e 0x0
step 1
wire_peek GCD.io_v
wire_peek GCD.io_z
quit
EOF
cat >test.flo <<EOF
GCD::io_z = out'16 GCD::x
T0 = sub'16 GCD::x GCD::y
T1 = lt'16 GCD::y GCD::x
T2 = mux T1 T0 GCD::x
GCD::io_a = in'16
GCD::io_e = in'1
T3 = mux GCD::io_e GCD::io_a T2
GCD::x = reg'16 1 T3
T4 = sub'16 GCD::y GCD::x
T5 = lt'16 GCD::y GCD::x
T6 = not'1 T5
T7 = mux T6 T4 GCD::y
GCD::io_b = in'16
T8 = mux GCD::io_e GCD::io_b T7
GCD::y = reg'16 1 T8
T9 = eq GCD::y 0'16
GCD::io_v = out'1 T9
EOF
ln -s GCD.vcd test.vcd
#include "harness.bash"
