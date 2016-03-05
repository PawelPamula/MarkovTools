#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ecrypt-sync.h"


int main(int argc, const char* argv[])
{
	if(argc < 3)
	{
		fprintf(stderr, "Usage: rabbit [length] [128bit key]\n");
		return -1;
	}
	char *pEnd;
	u64 length = strtoull(argv[1], &pEnd, 10);
	char keystr[] = "00000000000000000000000000000000";
	size_t len = strlen(argv[2]);
	strcpy(&(keystr[32-len]), argv[2]);
	
	char *pos = keystr;
	u8 key[16], iv[8], output[16], msg[16];
	for(int i = 0; i < 16; ++i)
	{
		sscanf(pos, "%2hhx", &key[i]);
		msg[i] = 0;
		output[i] = 0;
		iv[i/2] = 0;
		pos += 2;
	}
	/* At this point we have parsed arguments */
	
	ECRYPT_ctx ctx;
	ECRYPT_init();
	ECRYPT_keysetup(&ctx, key, 128, 64);
	ECRYPT_ivsetup(&ctx, iv);
	
	for(int i=0; i<length; i+=16)
	{
		ECRYPT_process_bytes(0, &ctx, msg, output, 16);
		for(int j=0; j<16; ++i)
			putchar(output[j]);
	}
	
	return 0;
}