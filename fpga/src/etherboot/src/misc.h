// Transitional declarations

#include <stdint.h>

enum {hash_length = 16};

#define EXTRACT_FIELD(val, which) (((val) & (which)) / ((which) & ~((which)-1)))
#define INSERT_FIELD(val, which, fieldval) (((val) & ~(which)) | ((fieldval) * ((which) & ~((which)-1))))

extern uint8_t *hash_buf(const void *in_buf, int count);
