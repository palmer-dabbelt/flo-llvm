#include "tempdir.bash"
cat >harness.c++ <<EOF
 #include "test.h"

int main (int argc, char* argv[]) {
  Tbl_t* c = new Tbl_t();
  c->init();
  FILE *f = fopen("Tbl.vcd", "w");
  FILE *tee = fopen("Tbl.stdin", "w");
  c->read_eval_print(f, tee);
  fclose(f);
  fclose(tee);
}
EOF
cat >emulator.h <<EOF
#ifndef __IS_EMULATOR__
#define __IS_EMULATOR__

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
    for (int i = 0; i < nw; i++) {
      if (s0[i] == s1[i]) {
        d[0] = 1;
        return;
      }
    }
    d[0] = 0;
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

// Abstract dat_t with a basic width-independent interface.
class dat_base_t {
 public:
  // Returns the bitwidth of this data.
  virtual int width() = 0;
  virtual string to_str() = 0;  // TODO(ducky): define standardized interface and expected output.
                                // Also allow different bases and representations (with defaults).
  virtual bool set_from_str(string val) = 0;    // TODO(ducky): define standardized interface and input format
                                                // allowing multiple representations (0x, 0h, 0b, ...).
  virtual dat_base_t* copy() = 0;   // this is an AWFUL hack to get around the awful templating
                                    // to be able to create an object of the same width
                                    // for fast compare operations
  virtual bool equals(dat_base_t& other) = 0;
};

template <int w>
class dat_t : public dat_base_t {
 public:
  const static int n_words = ((w - 1) / 64) + 1;
  // const static int n_words = (w >> CeilLog<sizeof(val_t)*8>::v) + 1;
  val_t values[n_words];
  inline int width ( void ) { return w; }
  inline int n_words_of ( void ) { return n_words; }
  inline bool to_bool ( void ) { return lo_word() != 0; }
  inline val_t lo_word ( void ) { return values[0]; }
  inline unsigned long to_ulong ( void ) { return (unsigned long)lo_word(); }
  dat_base_t* copy() {
    return new dat_t<w>(*this);
  }
  bool equals(dat_base_t& other) {
    dat_t<w> *other_ptr = dynamic_cast<dat_t<w>*>(&other);
    if (other_ptr == NULL) {
        return false;
    }
    dat_t<1> equals = *other_ptr == *this;
    return equals.values[0];
  }
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
  virtual bool set_from_str(string val) {
    return dat_from_str(val, *this);
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

// Abstract mem_t with a basic width- and size-independent interface.
class mem_base_t {
 public:
  // Returns the bitwidth of each memory element
  virtual int width() = 0;
  // Returns the number of elements in this memory
  virtual int length() = 0;
  virtual string get_to_str(string index) = 0;  // TODO(ducky): standardize (see dat_base_t).
  virtual bool put_from_str(string index, string val) = 0;   // TODO(ducky): standardize (see dat_base_t).
};

template <int w, int d>
class mem_t : public mem_base_t {
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
  string get_to_str(string index) {
    dat_t<w> val = get(atoi(index.c_str()));
    return val.to_str();
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
  bool put_from_str(string index, string val) {
    int i = atoi(index.c_str());
    if (i > length()) {
        cout << "mem_t::put_from_str: Index " << index << " out of range (max: " << length() << ")" << endl;
        return false;
    }
    dat_t<w> dat_val;
    dat_val.set_from_str(val);
    put(i, dat_val);
    return true;
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
 * Creates a dat_t from a std::string, where the string radix is automatically determined
 * from the string, or defaults to 10.
 * Returns true on success and false on failure.
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
            cout << "dat_from_str: Invalid character '" << c << "'" << endl;
            return false;
        }
        if (c_val > radix /* || c_val < 0 */) {
            cout << "dat_from_str: Invalid character '" << c << "'" << endl;
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
  std::vector< mod_t* > children;
  virtual void init ( bool rand_init=false ) { };
  virtual void clock_lo ( dat_t<1> reset ) { };
  virtual void clock_hi ( dat_t<1> reset ) { };
  virtual int  clock ( dat_t<1> reset ) { };
  virtual void setClocks ( std::vector< int >& periods ) { };
  
  virtual void print ( FILE* f ) { };
  virtual void dump ( FILE* f, int t ) { };
  
  virtual void init_debug_interface ( ) { };
  
  // Lists containing node/mem names to pointers, to be populated by init().
  map<string, dat_base_t*> nodes;
  map<string, mem_base_t*> mems;
  
  // Returns a list of all nodes accessible by the debugging interface.
  virtual vector<string> get_nodes() {
    vector<string> res;
    typedef std::map<std::string, dat_base_t*>::iterator it_type;
    for(it_type iterator = nodes.begin(); iterator != nodes.end(); iterator++) 
      res.push_back(iterator->first);
    return res;
  }
  // Returns a list of all memory objects accessible by the debugging interface.
  virtual vector<string> get_mems() {
    vector<string> res;
    typedef std::map<std::string, mem_base_t*>::iterator it_type;
    for(it_type iterator = mems.begin(); iterator != mems.end(); iterator++) 
      res.push_back(iterator->first);
    return res;
  }
  // Reads the value on a node. Returns empty on error.
  virtual string node_read(string name) {
    dat_base_t* dat = nodes[name];
    if (dat != NULL) {
      return dat->to_str();
    } else {
      cerr << "mod_t::node_read: Unable to find node '" << name << "'" << endl;
      return "0";
    }
  }
  // Writes a value to a node. Returns true on success and false on error.
  // Recommended to only be used on state elements.
  virtual bool node_write(string name, string val) {
    dat_base_t* dat = nodes[name];
    if (dat != NULL) {
      bool success = dat->set_from_str(val);
      return success;
    } else {
      cerr << "mod_t::node_write: Unable to find node '" << name << "'" << endl;
      return false;
    }
  }
  // Reads the an element from a memory.
  virtual string mem_read(string name, string index) {
    mem_base_t* mem = mems[name];
    if (mem != NULL) {
      return mem->get_to_str(index);
    } else {
      cerr << "mod_t::mem_read: Unable to find mem '" << name << "'" << endl;
      return "0";
    }
  }
  // Writes an element to a memory.
  virtual bool mem_write(string name, string index, string val) {
    mem_base_t* mem = mems[name];
    if (mem != NULL) {
      bool success = mem->put_from_str(index, val);
      return success;
    } else {
      cerr << "mod_t::mem_write: Unable to find mem '" << name << "'" << endl;
      return false;
    }
  }
  
  // Clocks in a reset
  virtual void reset() {
    clock_lo(dat_t<1>(1));
    clock_hi(dat_t<1>(1));
    clock_lo(dat_t<1>(1));
  }
  
  // Clocks one cycle
  virtual void cycle() {
    clock_lo(dat_t<1>(0));
    clock_hi(dat_t<1>(0));
    clock_lo(dat_t<1>(0));
  }
  
  // Clocks until a node is equal to the value.
  // Returns the number of cycles executed or -1 if the maximum was exceeded
  // or -2 if some error was encountered.
  virtual int clock_until_node_equal(string name, string val, int max=1000000) {
    int cycles = 0;
    dat_base_t* target_dat = nodes[name];
    dat_base_t* target_val = target_dat->copy();
    target_val->set_from_str(val);
    
    while (true) {
        if (target_dat->equals(*target_val)) {
            return cycles;
        } else {
            cycles++;
            cycle();
            if (cycles >= max) {
                return -1;
            }
        }
    }
  }
  
  // Clocks until a node is equal to the value.
  // Returns the number of cycles executed or -1 if the maximum was exceeded
  // or -2 if some error was encountered.
  virtual int clock_until_node_not_equal(string name, string val, int max=1000000) {
    int cycles = 0;
    dat_base_t* target_dat = nodes[name];
    int w = target_dat->width();
    dat_base_t* target_val = target_dat->copy();
    target_val->set_from_str(val);
    
    while (true) {
        if (!target_dat->equals(*target_val)) {
            return cycles;
        } else {
            cycles++;
            cycle();
            if (cycles >= max) {
                return -1;
            }
        }
    }
  }

  int timestep;

  int step (bool is_reset, int n, FILE* f, bool is_print = false) {
    int delta = 0;
    // fprintf(stderr, "STEP %d R %d P %d\n", n, is_reset, is_print);
    for (int i = 0; i < n; i++) {
      dat_t<1> reset = LIT<1>(is_reset); 
      delta += clock(reset);
      if (f != NULL) dump(f, timestep);
      if (is_print) print(stderr);
      timestep += 1;
    }
    return delta;
  }

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

  void read_eval_print (FILE *f, FILE *teefile = NULL) {
    timestep = 0;
    for (;;) {
      std::string str_in;
      getline(cin,str_in);
      if (teefile != NULL) {
          fprintf(teefile, "%s\n", str_in.c_str());
          fflush(teefile);
      }
      if (strcmp("", str_in.c_str()) == 0) {
          fprintf(stderr, "Read empty string in tester stdin\n");
          abort();
      }
      std::vector< std::string > tokens = tokenize(str_in);
      std::string cmd = tokens[0];
      if (cmd == "peek") {
        std::string res;
        if (tokens.size() == 2) {
          res = node_read(tokens[1]);
        } else if (tokens.size() == 3) {
          res = mem_read(tokens[1], tokens[2]);
        }
        // fprintf(stderr, "-PEEK %s -> %s\n", tokens[1].c_str(), res.c_str());
        cout << res << endl;
      } else if (cmd == "poke") {
        bool res;
        // fprintf(stderr, "-POKE %s <- %s\n", tokens[1].c_str(), tokens[2].c_str());
        if (tokens.size() == 3)
          res = node_write(tokens[1], tokens[2]);
        else if (tokens.size() == 4)
          res = mem_write(tokens[1], tokens[2], tokens[3]);
      } else if (cmd == "step") {
        int n = atoi(tokens[1].c_str());
        // fprintf(stderr, "-STEP %d\n", n);
        int new_delta = step(0, n, f, true);
        cout << new_delta << endl;
      } else if (cmd == "reset") {
        int n = atoi(tokens[1].c_str());
        // fprintf(stderr, "-RESET %d\n", n);
        step(1, n, f, false);
      } else if (cmd == "set-clocks") {
        std::vector< int > periods;
        for (int i = 1; i < tokens.size(); i++) {
          int period = atoi(tokens[i].c_str());
          periods.push_back(period);
        }
        setClocks(periods);
      } else if (cmd == "quit") {
          return;
      } else {
        fprintf(stderr, "Unknown command: |%s|\n", cmd.c_str());
      }
    }
  }


};

#define ASSERT(cond, msg) { \
  if (!(cond)) \
    throw std::runtime_error("Assertion failed: " msg); \
}

#pragma GCC diagnostic pop
#endif
EOF
cat >gold.vcd <<"EOF"
$timescale 1ps $end
$scope module Tbl $end
$var wire 8 N0 r_0 $end
$var wire 8 N1 r_1 $end
$var wire 8 N2 r_2 $end
$var wire 8 N3 r_3 $end
$var wire 8 N4 r_4 $end
$var wire 8 N5 r_5 $end
$var wire 8 N6 r_6 $end
$var wire 8 N7 r_7 $end
$var wire 8 N8 r_8 $end
$var wire 8 N9 r_9 $end
$var wire 8 N10 r_10 $end
$var wire 8 N11 r_11 $end
$var wire 8 N12 r_12 $end
$var wire 8 N13 r_13 $end
$var wire 8 N14 r_14 $end
$var wire 8 N15 r_15 $end
$var wire 8 N16 r_16 $end
$var wire 8 N17 r_17 $end
$var wire 8 N18 r_18 $end
$var wire 8 N19 r_19 $end
$var wire 8 N20 r_20 $end
$var wire 8 N21 r_21 $end
$var wire 8 N22 r_22 $end
$var wire 8 N23 r_23 $end
$var wire 8 N24 r_24 $end
$var wire 8 N25 r_25 $end
$var wire 8 N26 r_26 $end
$var wire 8 N27 r_27 $end
$var wire 8 N28 r_28 $end
$var wire 8 N29 r_29 $end
$var wire 8 N30 r_30 $end
$var wire 8 N31 r_31 $end
$var wire 8 N32 r_32 $end
$var wire 8 N33 r_33 $end
$var wire 8 N34 r_34 $end
$var wire 8 N35 r_35 $end
$var wire 8 N36 r_36 $end
$var wire 8 N37 r_37 $end
$var wire 8 N38 r_38 $end
$var wire 8 N39 r_39 $end
$var wire 8 N40 r_40 $end
$var wire 8 N41 r_41 $end
$var wire 8 N42 r_42 $end
$var wire 8 N43 r_43 $end
$var wire 8 N44 r_44 $end
$var wire 8 N45 r_45 $end
$var wire 8 N46 r_46 $end
$var wire 8 N47 r_47 $end
$var wire 8 N48 r_48 $end
$var wire 8 N49 r_49 $end
$var wire 8 N50 r_50 $end
$var wire 8 N51 r_51 $end
$var wire 8 N52 r_52 $end
$var wire 8 N53 r_53 $end
$var wire 8 N54 r_54 $end
$var wire 8 N55 r_55 $end
$var wire 8 N56 r_56 $end
$var wire 8 N57 r_57 $end
$var wire 8 N58 r_58 $end
$var wire 8 N59 r_59 $end
$var wire 8 N60 r_60 $end
$var wire 8 N61 r_61 $end
$var wire 8 N62 r_62 $end
$var wire 8 N63 r_63 $end
$var wire 8 N64 r_64 $end
$var wire 8 N65 r_65 $end
$var wire 8 N66 r_66 $end
$var wire 8 N67 r_67 $end
$var wire 8 N68 r_68 $end
$var wire 8 N69 r_69 $end
$var wire 8 N70 r_70 $end
$var wire 8 N71 r_71 $end
$var wire 8 N72 r_72 $end
$var wire 8 N73 r_73 $end
$var wire 8 N74 r_74 $end
$var wire 8 N75 r_75 $end
$var wire 8 N76 r_76 $end
$var wire 8 N77 r_77 $end
$var wire 8 N78 r_78 $end
$var wire 8 N79 r_79 $end
$var wire 8 N80 r_80 $end
$var wire 8 N81 r_81 $end
$var wire 8 N82 r_82 $end
$var wire 8 N83 r_83 $end
$var wire 8 N84 r_84 $end
$var wire 8 N85 r_85 $end
$var wire 8 N86 r_86 $end
$var wire 8 N87 r_87 $end
$var wire 8 N88 r_88 $end
$var wire 8 N89 r_89 $end
$var wire 8 N90 r_90 $end
$var wire 8 N91 r_91 $end
$var wire 8 N92 r_92 $end
$var wire 8 N93 r_93 $end
$var wire 8 N94 r_94 $end
$var wire 8 N95 r_95 $end
$var wire 8 N96 r_96 $end
$var wire 8 N97 r_97 $end
$var wire 8 N98 r_98 $end
$var wire 8 N99 r_99 $end
$var wire 8 N100 r_100 $end
$var wire 8 N101 r_101 $end
$var wire 8 N102 r_102 $end
$var wire 8 N103 r_103 $end
$var wire 8 N104 r_104 $end
$var wire 8 N105 r_105 $end
$var wire 8 N106 r_106 $end
$var wire 8 N107 r_107 $end
$var wire 8 N108 r_108 $end
$var wire 8 N109 r_109 $end
$var wire 8 N110 r_110 $end
$var wire 8 N111 r_111 $end
$var wire 8 N112 r_112 $end
$var wire 8 N113 r_113 $end
$var wire 8 N114 r_114 $end
$var wire 8 N115 r_115 $end
$var wire 8 N116 r_116 $end
$var wire 8 N117 r_117 $end
$var wire 8 N118 r_118 $end
$var wire 8 N119 r_119 $end
$var wire 8 N120 r_120 $end
$var wire 8 N121 r_121 $end
$var wire 8 N122 r_122 $end
$var wire 8 N123 r_123 $end
$var wire 8 N124 r_124 $end
$var wire 8 N125 r_125 $end
$var wire 8 N126 r_126 $end
$var wire 8 N127 r_127 $end
$var wire 8 N128 r_128 $end
$var wire 8 N129 r_129 $end
$var wire 8 N130 r_130 $end
$var wire 8 N131 r_131 $end
$var wire 8 N132 r_132 $end
$var wire 8 N133 r_133 $end
$var wire 8 N134 r_134 $end
$var wire 8 N135 r_135 $end
$var wire 8 N136 r_136 $end
$var wire 8 N137 r_137 $end
$var wire 8 N138 r_138 $end
$var wire 8 N139 r_139 $end
$var wire 8 N140 r_140 $end
$var wire 8 N141 r_141 $end
$var wire 8 N142 r_142 $end
$var wire 8 N143 r_143 $end
$var wire 8 N144 r_144 $end
$var wire 8 N145 r_145 $end
$var wire 8 N146 r_146 $end
$var wire 8 N147 r_147 $end
$var wire 8 N148 r_148 $end
$var wire 8 N149 r_149 $end
$var wire 8 N150 r_150 $end
$var wire 8 N151 r_151 $end
$var wire 8 N152 r_152 $end
$var wire 8 N153 r_153 $end
$var wire 8 N154 r_154 $end
$var wire 8 N155 r_155 $end
$var wire 8 N156 r_156 $end
$var wire 8 N157 r_157 $end
$var wire 8 N158 r_158 $end
$var wire 8 N159 r_159 $end
$var wire 8 N160 r_160 $end
$var wire 8 N161 r_161 $end
$var wire 8 N162 r_162 $end
$var wire 8 N163 r_163 $end
$var wire 8 N164 r_164 $end
$var wire 8 N165 r_165 $end
$var wire 8 N166 r_166 $end
$var wire 8 N167 r_167 $end
$var wire 8 N168 r_168 $end
$var wire 8 N169 r_169 $end
$var wire 8 N170 r_170 $end
$var wire 8 N171 r_171 $end
$var wire 8 N172 r_172 $end
$var wire 8 N173 r_173 $end
$var wire 8 N174 r_174 $end
$var wire 8 N175 r_175 $end
$var wire 8 N176 r_176 $end
$var wire 8 N177 r_177 $end
$var wire 8 N178 r_178 $end
$var wire 8 N179 r_179 $end
$var wire 8 N180 r_180 $end
$var wire 8 N181 r_181 $end
$var wire 8 N182 r_182 $end
$var wire 8 N183 r_183 $end
$var wire 8 N184 r_184 $end
$var wire 8 N185 r_185 $end
$var wire 8 N186 r_186 $end
$var wire 8 N187 r_187 $end
$var wire 8 N188 r_188 $end
$var wire 8 N189 r_189 $end
$var wire 8 N190 r_190 $end
$var wire 8 N191 r_191 $end
$var wire 8 N192 r_192 $end
$var wire 8 N193 r_193 $end
$var wire 8 N194 r_194 $end
$var wire 8 N195 r_195 $end
$var wire 8 N196 r_196 $end
$var wire 8 N197 r_197 $end
$var wire 8 N198 r_198 $end
$var wire 8 N199 r_199 $end
$var wire 8 N200 r_200 $end
$var wire 8 N201 r_201 $end
$var wire 8 N202 r_202 $end
$var wire 8 N203 r_203 $end
$var wire 8 N204 r_204 $end
$var wire 8 N205 r_205 $end
$var wire 8 N206 r_206 $end
$var wire 8 N207 r_207 $end
$var wire 8 N208 r_208 $end
$var wire 8 N209 r_209 $end
$var wire 8 N210 r_210 $end
$var wire 8 N211 r_211 $end
$var wire 8 N212 r_212 $end
$var wire 8 N213 r_213 $end
$var wire 8 N214 r_214 $end
$var wire 8 N215 r_215 $end
$var wire 8 N216 r_216 $end
$var wire 8 N217 r_217 $end
$var wire 8 N218 r_218 $end
$var wire 8 N219 r_219 $end
$var wire 8 N220 r_220 $end
$var wire 8 N221 r_221 $end
$var wire 8 N222 r_222 $end
$var wire 8 N223 r_223 $end
$var wire 8 N224 r_224 $end
$var wire 8 N225 r_225 $end
$var wire 8 N226 r_226 $end
$var wire 8 N227 r_227 $end
$var wire 8 N228 r_228 $end
$var wire 8 N229 r_229 $end
$var wire 8 N230 r_230 $end
$var wire 8 N231 r_231 $end
$var wire 8 N232 r_232 $end
$var wire 8 N233 r_233 $end
$var wire 8 N234 r_234 $end
$var wire 8 N235 r_235 $end
$var wire 8 N236 r_236 $end
$var wire 8 N237 r_237 $end
$var wire 8 N238 r_238 $end
$var wire 8 N239 r_239 $end
$var wire 8 N240 r_240 $end
$var wire 8 N241 r_241 $end
$var wire 8 N242 r_242 $end
$var wire 8 N243 r_243 $end
$var wire 8 N244 r_244 $end
$var wire 8 N245 r_245 $end
$var wire 8 N246 r_246 $end
$var wire 8 N247 r_247 $end
$var wire 8 N248 r_248 $end
$var wire 8 N249 r_249 $end
$var wire 8 N250 r_250 $end
$var wire 8 N251 r_251 $end
$var wire 8 N252 r_252 $end
$var wire 8 N253 r_253 $end
$var wire 8 N254 r_254 $end
$var wire 8 N255 r_255 $end
$var wire 8 N256 io_addr $end
$var wire 8 N257 io_out $end
$upscope $end
$enddefinitions $end
$dumpvars
$end
#0
b00000000 N0
b00000001 N1
b00000010 N2
b00000011 N3
b00000100 N4
b00000101 N5
b00000110 N6
b00000111 N7
b00001000 N8
b00001001 N9
b00001010 N10
b00001011 N11
b00001100 N12
b00001101 N13
b00001110 N14
b00001111 N15
b00010000 N16
b00010001 N17
b00010010 N18
b00010011 N19
b00010100 N20
b00010101 N21
b00010110 N22
b00010111 N23
b00011000 N24
b00011001 N25
b00011010 N26
b00011011 N27
b00011100 N28
b00011101 N29
b00011110 N30
b00011111 N31
b00100000 N32
b00100001 N33
b00100010 N34
b00100011 N35
b00100100 N36
b00100101 N37
b00100110 N38
b00100111 N39
b00101000 N40
b00101001 N41
b00101010 N42
b00101011 N43
b00101100 N44
b00101101 N45
b00101110 N46
b00101111 N47
b00110000 N48
b00110001 N49
b00110010 N50
b00110011 N51
b00110100 N52
b00110101 N53
b00110110 N54
b00110111 N55
b00111000 N56
b00111001 N57
b00111010 N58
b00111011 N59
b00111100 N60
b00111101 N61
b00111110 N62
b00111111 N63
b01000000 N64
b01000001 N65
b01000010 N66
b01000011 N67
b01000100 N68
b01000101 N69
b01000110 N70
b01000111 N71
b01001000 N72
b01001001 N73
b01001010 N74
b01001011 N75
b01001100 N76
b01001101 N77
b01001110 N78
b01001111 N79
b01010000 N80
b01010001 N81
b01010010 N82
b01010011 N83
b01010100 N84
b01010101 N85
b01010110 N86
b01010111 N87
b01011000 N88
b01011001 N89
b01011010 N90
b01011011 N91
b01011100 N92
b01011101 N93
b01011110 N94
b01011111 N95
b01100000 N96
b01100001 N97
b01100010 N98
b01100011 N99
b01100100 N100
b01100101 N101
b01100110 N102
b01100111 N103
b01101000 N104
b01101001 N105
b01101010 N106
b01101011 N107
b01101100 N108
b01101101 N109
b01101110 N110
b01101111 N111
b01110000 N112
b01110001 N113
b01110010 N114
b01110011 N115
b01110100 N116
b01110101 N117
b01110110 N118
b01110111 N119
b01111000 N120
b01111001 N121
b01111010 N122
b01111011 N123
b01111100 N124
b01111101 N125
b01111110 N126
b01111111 N127
b10000000 N128
b10000001 N129
b10000010 N130
b10000011 N131
b10000100 N132
b10000101 N133
b10000110 N134
b10000111 N135
b10001000 N136
b10001001 N137
b10001010 N138
b10001011 N139
b10001100 N140
b10001101 N141
b10001110 N142
b10001111 N143
b10010000 N144
b10010001 N145
b10010010 N146
b10010011 N147
b10010100 N148
b10010101 N149
b10010110 N150
b10010111 N151
b10011000 N152
b10011001 N153
b10011010 N154
b10011011 N155
b10011100 N156
b10011101 N157
b10011110 N158
b10011111 N159
b10100000 N160
b10100001 N161
b10100010 N162
b10100011 N163
b10100100 N164
b10100101 N165
b10100110 N166
b10100111 N167
b10101000 N168
b10101001 N169
b10101010 N170
b10101011 N171
b10101100 N172
b10101101 N173
b10101110 N174
b10101111 N175
b10110000 N176
b10110001 N177
b10110010 N178
b10110011 N179
b10110100 N180
b10110101 N181
b10110110 N182
b10110111 N183
b10111000 N184
b10111001 N185
b10111010 N186
b10111011 N187
b10111100 N188
b10111101 N189
b10111110 N190
b10111111 N191
b11000000 N192
b11000001 N193
b11000010 N194
b11000011 N195
b11000100 N196
b11000101 N197
b11000110 N198
b11000111 N199
b11001000 N200
b11001001 N201
b11001010 N202
b11001011 N203
b11001100 N204
b11001101 N205
b11001110 N206
b11001111 N207
b11010000 N208
b11010001 N209
b11010010 N210
b11010011 N211
b11010100 N212
b11010101 N213
b11010110 N214
b11010111 N215
b11011000 N216
b11011001 N217
b11011010 N218
b11011011 N219
b11011100 N220
b11011101 N221
b11011110 N222
b11011111 N223
b11100000 N224
b11100001 N225
b11100010 N226
b11100011 N227
b11100100 N228
b11100101 N229
b11100110 N230
b11100111 N231
b11101000 N232
b11101001 N233
b11101010 N234
b11101011 N235
b11101100 N236
b11101101 N237
b11101110 N238
b11101111 N239
b11110000 N240
b11110001 N241
b11110010 N242
b11110011 N243
b11110100 N244
b11110101 N245
b11110110 N246
b11110111 N247
b11111000 N248
b11111001 N249
b11111010 N250
b11111011 N251
b11111100 N252
b11111101 N253
b11111110 N254
b11111111 N255
b00000000 N256
b00000000 N257
#1
#2
#3
#4
#5
b10111011 N256
b10111011 N257
#6
b11010100 N256
b11010100 N257
#7
b00111101 N256
b00111101 N257
#8
b10011011 N256
b10011011 N257
#9
b10100011 N256
b10100011 N257
#10
b01001111 N256
b01001111 N257
#11
b10001100 N256
b10001100 N257
#12
b00011101 N256
b00011101 N257
#13
b10011000 N256
b10011000 N257
#14
b11001000 N256
b11001000 N257
#15
b01010101 N256
b01010101 N257
#16
b01000000 N256
b01000000 N257
#17
b01100010 N256
b01100010 N257
#18
b10011100 N256
b10011100 N257
#19
b11111100 N256
b11111100 N257
#20
b11111011 N256
b11111011 N257
EOF
cat >test.stdin <<EOF
reset 5
poke Tbl.io_addr 0xbb
step 1
peek Tbl.io_out
poke Tbl.io_addr 0xd4
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x3d
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x9b
step 1
peek Tbl.io_out
poke Tbl.io_addr 0xa3
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x4f
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x8c
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x1d
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x98
step 1
peek Tbl.io_out
poke Tbl.io_addr 0xc8
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x55
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x40
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x62
step 1
peek Tbl.io_out
poke Tbl.io_addr 0x9c
step 1
peek Tbl.io_out
poke Tbl.io_addr 0xfc
step 1
peek Tbl.io_out
poke Tbl.io_addr 0xfb
step 1
peek Tbl.io_out
quit
EOF
cat >test.flo <<EOF
Tbl::r_0 = out/8 0
Tbl::r_1 = out/8 1
Tbl::r_2 = out/8 2
Tbl::r_3 = out/8 3
Tbl::r_4 = out/8 4
Tbl::r_5 = out/8 5
Tbl::r_6 = out/8 6
Tbl::r_7 = out/8 7
Tbl::r_8 = out/8 8
Tbl::r_9 = out/8 9
Tbl::r_10 = out/8 10
Tbl::r_11 = out/8 11
Tbl::r_12 = out/8 12
Tbl::r_13 = out/8 13
Tbl::r_14 = out/8 14
Tbl::r_15 = out/8 15
Tbl::r_16 = out/8 16
Tbl::r_17 = out/8 17
Tbl::r_18 = out/8 18
Tbl::r_19 = out/8 19
Tbl::r_20 = out/8 20
Tbl::r_21 = out/8 21
Tbl::r_22 = out/8 22
Tbl::r_23 = out/8 23
Tbl::r_24 = out/8 24
Tbl::r_25 = out/8 25
Tbl::r_26 = out/8 26
Tbl::r_27 = out/8 27
Tbl::r_28 = out/8 28
Tbl::r_29 = out/8 29
Tbl::r_30 = out/8 30
Tbl::r_31 = out/8 31
Tbl::r_32 = out/8 32
Tbl::r_33 = out/8 33
Tbl::r_34 = out/8 34
Tbl::r_35 = out/8 35
Tbl::r_36 = out/8 36
Tbl::r_37 = out/8 37
Tbl::r_38 = out/8 38
Tbl::r_39 = out/8 39
Tbl::r_40 = out/8 40
Tbl::r_41 = out/8 41
Tbl::r_42 = out/8 42
Tbl::r_43 = out/8 43
Tbl::r_44 = out/8 44
Tbl::r_45 = out/8 45
Tbl::r_46 = out/8 46
Tbl::r_47 = out/8 47
Tbl::r_48 = out/8 48
Tbl::r_49 = out/8 49
Tbl::r_50 = out/8 50
Tbl::r_51 = out/8 51
Tbl::r_52 = out/8 52
Tbl::r_53 = out/8 53
Tbl::r_54 = out/8 54
Tbl::r_55 = out/8 55
Tbl::r_56 = out/8 56
Tbl::r_57 = out/8 57
Tbl::r_58 = out/8 58
Tbl::r_59 = out/8 59
Tbl::r_60 = out/8 60
Tbl::r_61 = out/8 61
Tbl::r_62 = out/8 62
Tbl::r_63 = out/8 63
Tbl::r_64 = out/8 64
Tbl::r_65 = out/8 65
Tbl::r_66 = out/8 66
Tbl::r_67 = out/8 67
Tbl::r_68 = out/8 68
Tbl::r_69 = out/8 69
Tbl::r_70 = out/8 70
Tbl::r_71 = out/8 71
Tbl::r_72 = out/8 72
Tbl::r_73 = out/8 73
Tbl::r_74 = out/8 74
Tbl::r_75 = out/8 75
Tbl::r_76 = out/8 76
Tbl::r_77 = out/8 77
Tbl::r_78 = out/8 78
Tbl::r_79 = out/8 79
Tbl::r_80 = out/8 80
Tbl::r_81 = out/8 81
Tbl::r_82 = out/8 82
Tbl::r_83 = out/8 83
Tbl::r_84 = out/8 84
Tbl::r_85 = out/8 85
Tbl::r_86 = out/8 86
Tbl::r_87 = out/8 87
Tbl::r_88 = out/8 88
Tbl::r_89 = out/8 89
Tbl::r_90 = out/8 90
Tbl::r_91 = out/8 91
Tbl::r_92 = out/8 92
Tbl::r_93 = out/8 93
Tbl::r_94 = out/8 94
Tbl::r_95 = out/8 95
Tbl::r_96 = out/8 96
Tbl::r_97 = out/8 97
Tbl::r_98 = out/8 98
Tbl::r_99 = out/8 99
Tbl::r_100 = out/8 100
Tbl::r_101 = out/8 101
Tbl::r_102 = out/8 102
Tbl::r_103 = out/8 103
Tbl::r_104 = out/8 104
Tbl::r_105 = out/8 105
Tbl::r_106 = out/8 106
Tbl::r_107 = out/8 107
Tbl::r_108 = out/8 108
Tbl::r_109 = out/8 109
Tbl::r_110 = out/8 110
Tbl::r_111 = out/8 111
Tbl::r_112 = out/8 112
Tbl::r_113 = out/8 113
Tbl::r_114 = out/8 114
Tbl::r_115 = out/8 115
Tbl::r_116 = out/8 116
Tbl::r_117 = out/8 117
Tbl::r_118 = out/8 118
Tbl::r_119 = out/8 119
Tbl::r_120 = out/8 120
Tbl::r_121 = out/8 121
Tbl::r_122 = out/8 122
Tbl::r_123 = out/8 123
Tbl::r_124 = out/8 124
Tbl::r_125 = out/8 125
Tbl::r_126 = out/8 126
Tbl::r_127 = out/8 127
Tbl::r_128 = out/8 128
Tbl::r_129 = out/8 129
Tbl::r_130 = out/8 130
Tbl::r_131 = out/8 131
Tbl::r_132 = out/8 132
Tbl::r_133 = out/8 133
Tbl::r_134 = out/8 134
Tbl::r_135 = out/8 135
Tbl::r_136 = out/8 136
Tbl::r_137 = out/8 137
Tbl::r_138 = out/8 138
Tbl::r_139 = out/8 139
Tbl::r_140 = out/8 140
Tbl::r_141 = out/8 141
Tbl::r_142 = out/8 142
Tbl::r_143 = out/8 143
Tbl::r_144 = out/8 144
Tbl::r_145 = out/8 145
Tbl::r_146 = out/8 146
Tbl::r_147 = out/8 147
Tbl::r_148 = out/8 148
Tbl::r_149 = out/8 149
Tbl::r_150 = out/8 150
Tbl::r_151 = out/8 151
Tbl::r_152 = out/8 152
Tbl::r_153 = out/8 153
Tbl::r_154 = out/8 154
Tbl::r_155 = out/8 155
Tbl::r_156 = out/8 156
Tbl::r_157 = out/8 157
Tbl::r_158 = out/8 158
Tbl::r_159 = out/8 159
Tbl::r_160 = out/8 160
Tbl::r_161 = out/8 161
Tbl::r_162 = out/8 162
Tbl::r_163 = out/8 163
Tbl::r_164 = out/8 164
Tbl::r_165 = out/8 165
Tbl::r_166 = out/8 166
Tbl::r_167 = out/8 167
Tbl::r_168 = out/8 168
Tbl::r_169 = out/8 169
Tbl::r_170 = out/8 170
Tbl::r_171 = out/8 171
Tbl::r_172 = out/8 172
Tbl::r_173 = out/8 173
Tbl::r_174 = out/8 174
Tbl::r_175 = out/8 175
Tbl::r_176 = out/8 176
Tbl::r_177 = out/8 177
Tbl::r_178 = out/8 178
Tbl::r_179 = out/8 179
Tbl::r_180 = out/8 180
Tbl::r_181 = out/8 181
Tbl::r_182 = out/8 182
Tbl::r_183 = out/8 183
Tbl::r_184 = out/8 184
Tbl::r_185 = out/8 185
Tbl::r_186 = out/8 186
Tbl::r_187 = out/8 187
Tbl::r_188 = out/8 188
Tbl::r_189 = out/8 189
Tbl::r_190 = out/8 190
Tbl::r_191 = out/8 191
Tbl::r_192 = out/8 192
Tbl::r_193 = out/8 193
Tbl::r_194 = out/8 194
Tbl::r_195 = out/8 195
Tbl::r_196 = out/8 196
Tbl::r_197 = out/8 197
Tbl::r_198 = out/8 198
Tbl::r_199 = out/8 199
Tbl::r_200 = out/8 200
Tbl::r_201 = out/8 201
Tbl::r_202 = out/8 202
Tbl::r_203 = out/8 203
Tbl::r_204 = out/8 204
Tbl::r_205 = out/8 205
Tbl::r_206 = out/8 206
Tbl::r_207 = out/8 207
Tbl::r_208 = out/8 208
Tbl::r_209 = out/8 209
Tbl::r_210 = out/8 210
Tbl::r_211 = out/8 211
Tbl::r_212 = out/8 212
Tbl::r_213 = out/8 213
Tbl::r_214 = out/8 214
Tbl::r_215 = out/8 215
Tbl::r_216 = out/8 216
Tbl::r_217 = out/8 217
Tbl::r_218 = out/8 218
Tbl::r_219 = out/8 219
Tbl::r_220 = out/8 220
Tbl::r_221 = out/8 221
Tbl::r_222 = out/8 222
Tbl::r_223 = out/8 223
Tbl::r_224 = out/8 224
Tbl::r_225 = out/8 225
Tbl::r_226 = out/8 226
Tbl::r_227 = out/8 227
Tbl::r_228 = out/8 228
Tbl::r_229 = out/8 229
Tbl::r_230 = out/8 230
Tbl::r_231 = out/8 231
Tbl::r_232 = out/8 232
Tbl::r_233 = out/8 233
Tbl::r_234 = out/8 234
Tbl::r_235 = out/8 235
Tbl::r_236 = out/8 236
Tbl::r_237 = out/8 237
Tbl::r_238 = out/8 238
Tbl::r_239 = out/8 239
Tbl::r_240 = out/8 240
Tbl::r_241 = out/8 241
Tbl::r_242 = out/8 242
Tbl::r_243 = out/8 243
Tbl::r_244 = out/8 244
Tbl::r_245 = out/8 245
Tbl::r_246 = out/8 246
Tbl::r_247 = out/8 247
Tbl::r_248 = out/8 248
Tbl::r_249 = out/8 249
Tbl::r_250 = out/8 250
Tbl::r_251 = out/8 251
Tbl::r_252 = out/8 252
Tbl::r_253 = out/8 253
Tbl::r_254 = out/8 254
Tbl::r_255 = out/8 255
Tbl::io_addr = in/8
Tbl::io_out = out/8 T0
EOF
ln -s Tbl.vcd test.vcd
#include "harness.bash"
