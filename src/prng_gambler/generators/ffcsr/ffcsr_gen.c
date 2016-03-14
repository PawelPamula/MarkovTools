#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ecrypt-sync.h"

#define KEY_LEN 128
#define IV_LEN 128

int main(int argc, const char* argv[])
{
	if(argc < 3)
	{
		fprintf(stderr, "Usage: %s [length] [%dbit key]\n", argv[0], KEY_LEN);
		return -1;
	}
	char *pEnd;
	u64 length = strtoull(argv[1], &pEnd, 10);
	// fprintf(stderr, "Creating %ld output bytes\n", length);
	char keystr[KEY_LEN/4];
	for(int i = 0; i < KEY_LEN/4; ++i) keystr[i] = '0';
	size_t len = strlen(argv[2]);
	strcpy(&(keystr[KEY_LEN/4-len]), argv[2]);
	
	char *pos = keystr;
	u8 key[KEY_LEN/8], iv[IV_LEN/8], output[16], msg[16];
	for(int i = 0; i < KEY_LEN/8; ++i, pos += 2) sscanf(pos, "%2hhx", &key[i]);
	for(int i = 0; i < IV_LEN/8; ++i) iv[i] = 0;
	for(int i = 0; i < 16; ++i) msg[i] = output[i] = 0;
	
	/* At this point we have parsed arguments */
	
	ECRYPT_ctx ctx;
	ECRYPT_init();
	ECRYPT_keysetup(&ctx, key, KEY_LEN, IV_LEN);
	ECRYPT_ivsetup(&ctx, iv);
	for(int i=0; i<length; i+=16)
	{
		ECRYPT_process_bytes(0, &ctx, msg, output, 16);
		for(int j=0; j<16; ++j)
			putchar(output[j]);
	}
	
	return 0;
}
