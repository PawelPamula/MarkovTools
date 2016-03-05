/* ecrypt-plus.c */

#include "ecrypt-sync.h"

/**************************************************************
 * Supplemental functions to report back to Python the sizes
 * of keys, IVs, and the chunk size.
 *
 * Larry Bugbee, June 9, 2007
 **************************************************************/

int  getCtxSize()    { return sizeof(ECRYPT_ctx); }

int isValidKeySize(int straw) {       /* in bits */
    int i = 0;
    for (i=0; ECRYPT_KEYSIZE(i) <= ECRYPT_MAXKEYSIZE; ++i)
        if (straw == ECRYPT_KEYSIZE(i)) return 1;
    return 0;
}

int isValidIVSize(int straw) {        /* in bits */
    int i = 0;
    for (i=0; ECRYPT_IVSIZE(i) <= ECRYPT_MAXIVSIZE; ++i)
        if (straw == ECRYPT_IVSIZE(i)) return 1;
    return 0;
}

#ifdef DRAGON_BUFFER_BYTES                  /* Dragon  */
#define CHUNK_SIZE      DRAGON_BUFFER_BYTES
#elif ECRYPT_BLOCKLENGTH                    /* all but Dragon */
#define CHUNK_SIZE      ECRYPT_BLOCKLENGTH
#else
#define CHUNK_SIZE      0
#endif

int  getChunkSize()  { return CHUNK_SIZE; }

