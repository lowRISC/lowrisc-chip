// *Really* minimal PCG32 code / (c) 2014 M.E. O'Neill / pcg-random.org
// Licensed under Apache License 2.0 (NO WARRANTY, etc. see website)

#include <stdint.h>

typedef struct { uint64_t state;  uint64_t inc; } pcg32_random_t;

uint32_t pcg32_random_r(pcg32_random_t* rng)
{
    uint64_t oldstate = rng->state;
    // Advance internal state
    rng->state = oldstate * 6364136223846793005ULL + (rng->inc|1);
    // Calculate output function (XSH RR), uses old state for max ILP
    uint32_t xorshifted = ((oldstate >> 18u) ^ oldstate) >> 27u;
    uint32_t rot = oldstate >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

/* Return a random integer between 0 and RAND_MAX.  */
int
rand (void)
{
  static pcg32_random_t rng;
  return (int) pcg32_random_r(&rng);
}

unsigned int rand32(void)
{
  return ((unsigned int) rand() | ( (unsigned int) rand() << 16));
}

uint64_t rand64(void)
{
  uint64_t low = rand32(), high = rand32();
  return low | (high << 32);
}
