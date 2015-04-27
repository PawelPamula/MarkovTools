#include <stdio.h>
#include <stdlib.h>

typedef long long int64;
typedef unsigned int uint32;

const size_t intSize = 8 * sizeof(int);
const int maxRandBitIndex = 30;
int curr_seed;


void initSeed(void)
{
    curr_seed = 112358;
    srand(curr_seed);
}

void nextSeed(void)
{
    srand(++curr_seed);
}

int64 myPow(int64 a, uint32 b)
{
    int64 res = 1;
    for (uint32 i = 0; i < b; ++i)
        res *= a;
    return res;
}


void generateString(int64 length)
{
    int64 draws = length / intSize;
    uint32 curr = rand();
    uint32 next = rand();
    uint32 k = 1;
    for (int64 i = 0; i < draws; ++i)
    {
        curr += (next  << (32-k));
        //fprintf(stderr, "Rand: %u\n", curr);
        fwrite(&curr, sizeof(uint32), 1, stdout);
        if (k < 31)
        {
            curr = next >> k;
            next = rand();
            k++;
        }
        else
        {
            curr = rand();
            next = rand();
            k = 1;
        }
    }
}

void simulate(int64 length)
{
    int64 draws = length / intSize;
    
    for (int64 i = 0; i < draws; ++i)
    {
        rand();
    }
}

int main(int argc, char** argv)
{
    if (argc < 3)
    {
        printf("Usage: cprg [number of strings] [log2 of length]\n");
        return 0;
    }
    int64 nrOfStrings = atoi(argv[1]);
    uint32 logLength = atoi(argv[2]);
    int64 length = myPow(2LL, logLength);
    
    freopen (NULL, "wb", stdout);
    initSeed();
    fwrite(&nrOfStrings, sizeof(int64), 1, stdout);
    fwrite(&length, sizeof(int64), 1, stdout);
    for (int64 i = 0; i < nrOfStrings; ++i)
    {
        if (i % 100 == 0)
            fprintf(stderr, "Generator: %lld/%lld\n", i, nrOfStrings);
        
        generateString(length);
        //simulate(length);
        nextSeed();
    }
    
    return 0;
}
