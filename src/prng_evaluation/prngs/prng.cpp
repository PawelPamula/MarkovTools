#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <set>
#include <random>

typedef long long int64;
typedef unsigned long long uint64;
typedef int int32;
typedef unsigned int uint32;

using namespace std;

uint64 pow2[64];
uint64 pow2m1[65];

void initPow()
{
    pow2[0] = 1;
    pow2m1[0] = 0;
    pow2m1[64] = 1;
    for (int i = 1; i < 64; ++i)
    {
        pow2[i] = 2*pow2[i-1];
        pow2m1[i] = pow2[i] - 1;
        pow2m1[64] += pow2[i];
    }
}

void printPow()
{
    for (int i = 0; i < 64; ++i)
        printf("%llX\n", pow2[i]);
    for (int i = 0; i < 65; ++i)
        printf("%llX\n", pow2m1[i]);
}

class PRNG
{
public:
    virtual void setSeed(uint32 seed) = 0;
    virtual uint64 nextInt() = 0;
    virtual uint32 getNrOfBits() = 0;
};

class OneByte : public PRNG
{
public:
    OneByte(shared_ptr<PRNG> prng_, uint32 byteNr_)
        : prng(prng_)
        , byteNr(byteNr_)
    {
    }
    
    void setSeed(uint32 seed)
    {
        prng->setSeed(seed);
    }
    
    uint64 nextInt()
    {
        return getByte(prng->nextInt());
    }
    
    uint32 getNrOfBits()
    {
        return 8u;
    }
    
private:
    const shared_ptr<PRNG> prng;
    const uint32 byteNr;
    
    uint64 getByte(uint64 n)
    {
        n = n >> (byteNr * 8);
        return n & 255LLu;
    }
};

class SomeBits : public PRNG
{
public:
    SomeBits(shared_ptr<PRNG> prng_, uint32 mostSig_, uint32 leastSig_)
        : prng(prng_)
        , mostSig(mostSig_)
        , leastSig(leastSig_)
        , nrOfBits(mostSig_ + 1 - leastSig_)
    {
    }
    
    void setSeed(uint32 seed)
    {
        prng->setSeed(seed);
    }
    
    uint64 nextInt()
    {
        return getBits(prng->nextInt());
    }
    
    uint32 getNrOfBits()
    {
        return nrOfBits;
    }
    
private:
    const shared_ptr<PRNG> prng;
    const uint32 mostSig;
    const uint32 leastSig;
    const uint32 nrOfBits;
    
    uint64 getBits(uint64 n)
    {
        n = n >> leastSig;
        return n & pow2m1[nrOfBits];
    }
};

shared_ptr<PRNG> getShifted(shared_ptr<PRNG> prng, uint32 shift)
{
    uint32 mg = prng->getNrOfBits() - 1;
    uint32 lg = shift;
    return shared_ptr<PRNG>(new SomeBits(prng, mg, lg));
}


class LCG : public PRNG
{
public:
    const uint64 M;
    const uint64 a, b;
    const uint32 nrOfBits;
    
    LCG(uint64 M_, uint64 a_, uint64 b_, const uint32 nrOfBits_)
        : M(M_)
        , a(a_)
        , b(b_)
        , nrOfBits(nrOfBits_)
    {
    }
    
    void setSeed(uint32 seed)
    {
        this->seed = seed;
    }
    
    uint64 nextInt()
    {
        seed = (a * seed + b) % M;
        return seed & pow2m1[nrOfBits];
    }
    
    uint32 getNrOfBits()
    {
        return nrOfBits;
    }
    
private:
    uint64 seed = 1;
};

class CMRG : public PRNG
{
public:
    CMRG()
    {
        reset();
    }
    
    void setSeed(uint32 seed)
    {
        x[0] = 0;
        x[1] = seed;
        x[2] = 0;
        y[0] = 0;
        y[1] = 0;
        y[2] = seed;
        n = 0;
    }
    
    uint64 nextInt()
    {
        int64 nextx = xa *  x[(n+1)%3]  -  xb * x[n];
        int64 nexty = ya *  y[(n+2)%3]  -  yb * y[n];
        nextx = mymod(nextx, xm);
        nexty = mymod(nexty, ym);
        x[n] = nextx;
        y[n] = nexty;
        n = (n + 1)%3;
        return static_cast<uint64>( (zm + nextx - nexty) % zm );
    }
    
    uint32 getNrOfBits()
    {
        return 31;
    }
    
private:
    int64 x[3], y[3];
    const int64 xa = 63308;
    const int64 xb = 183326;
    const int64 xm = 2147483647LL;
    const int64 ya = 86098;
    const int64 yb = 539608;
    const int64 ym = 2145483479LL;
    const int64 zm = 2147483647LL;
    int n;
    
    void reset()
    {
        setSeed(1);
    }
    
    int64 mymod(int64 a, int64 m)
    {
        if (m == 0)
            return a;
        if (m < 0)
            return mymod(-a, -m);
        int64 res = a % m;
        if (res < 0)
            res += m;
        return res;
    }
};

class C_PRG : public PRNG
{
public:
    void setSeed(uint32 seed)
    {
        srand(seed);
    }
    
    uint64 nextInt()
    {
        return static_cast<uint64>(rand());
    }
    
    uint32 getNrOfBits()
    {
        return 31;
    }
};

class BorlandPRNG : public PRNG
{
    uint64 nextInt()
    {
        myseed = myseed * 0x015A4E35 + 1;
        return static_cast<uint64>( (myseed >> 16) & 0x7FFF );
    }
    
    void setSeed(uint32 seed)
    {
        myseed = seed;
        //myrand();
    }
    
    uint32 getNrOfBits()
    {
        return 15;
    }
    
private:
    uint32 myseed = 0x015A4E36;
};

class VisualPRNG : public PRNG
{
    uint64 nextInt()
    {
        myseed = myseed * 0x343FDu + 0x269EC3u;
        return static_cast<uint64>( (myseed >> 16) & 0x7FFF );
    }
    
    void setSeed(uint32 seed)
    {
        myseed = seed;
        //myrand();
    }
    
    uint32 getNrOfBits()
    {
        return 15;
    }
    
private:
    uint32 myseed = 1;
};

class Mersenne : public PRNG
{
public:
    void setSeed(uint32 seed)
    {
        eng.seed(seed);
    }
    
    uint64 nextInt()
    {
//         //uint64 r = static_cast<uint64>(eng());
        //fprintf(stderr, "%llu\n", r & pow2m1[63]);
        //return r & pow2m1[63];
        return static_cast<uint64>(eng());
    }
    
    uint32 getNrOfBits()
    {
        return 64;
    }
    
    mt19937_64 eng;
};

class RandU : public PRNG
{
public:
    void setSeed(uint32 seed)
    {
        s = seed + (seed % 2 == 0 ? 1 : 0);
    }
    
    uint64 nextInt()
    {
        s = (65539llu * s) % pow2[31];
        return s;
    }
    
    uint32 getNrOfBits()
    {
        return 31;
    }
    
    uint64 s;
};

class GeneratorInvoker
{
public:
    GeneratorInvoker() = default;
    
    GeneratorInvoker(shared_ptr<PRNG>& prng_)
        : prng(prng_)
    {
    }
    
    GeneratorInvoker(const GeneratorInvoker&) = delete;
    
    ~GeneratorInvoker()
    {
        if (seeds)
            fclose(seeds);
    }
    
    GeneratorInvoker& operator=(const GeneratorInvoker&) = delete;
    
    void setPRNG(PRNG& prng)
    {
        this->prng = shared_ptr<PRNG>(&prng);
    }
    
    void setPRNG(shared_ptr<PRNG>& prng)
    {
        this->prng = prng;
    }
    
    void setPathToSeeds(char* pathToFile)
    {
        seeds = fopen(pathToFile, "r");
        if (!seeds)
        {
            printf("Couldn't open %s\n", pathToFile);
            exit(1);
        }
    }
    
    void run(int64 nrOfStrings, int64 length)
    {
        fprintf(stderr, "GeneratorInvoker::run(%lld, %lld)\n", nrOfStrings, length);
        freopen (NULL, "wb", stdout);
        fwrite(&nrOfStrings, sizeof(int64), 1, stdout);
        fwrite(&length, sizeof(int64), 1, stdout);
        
        for (int64 i = 1; i <= nrOfStrings; ++i)
        {
            prng->setSeed(nextSeed());
            
            if (i % 100 == 0)
                fprintf(stderr, "Generator: %lld/%lld\n", i, nrOfStrings);
            generateString(length);
        }
        fclose(stdout);
    }
    
    void run(int64 length)
    {
        int nrOfStrings = getNextIntFromFile();
        run(nrOfStrings, length);
    }
    
private:
    shared_ptr<PRNG> prng;
    FILE* seeds = 0;
    uint64 curr;
    int filled;
    
    void generateString(uint64 nrOfBits)
    {
        uint64 nrOfChunks = nrOfBits / 64;
        curr = 0;
        filled = 0;
        for (uint64 i = 0; i < nrOfChunks; ++i)
        {
            uint64 chunk = nextChunk();
            //fprintf(stderr, "filled = %d\n", filled);
            fwrite(&chunk, sizeof(uint64), 1, stdout);
        }
    }
    
    uint64 nextChunk()
    {
        uint64 r = 0;
        int nrOfBits = prng->getNrOfBits();
        while (filled < 64)
        {
            r = prng->nextInt();
            curr += (r << filled);
            filled += nrOfBits;
        }
        int used = nrOfBits + 64 - filled;
        uint64 res = curr;
        curr = used < 64 ? (r >> used) : 0;
        filled = nrOfBits - used;
        return res;
    }
    
    int nextSeed()
    {
        static int def_first_seed = 112358;
        
        if (seeds)
            return getNextIntFromFile() + 1000000001;
        else
            return def_first_seed++;
    }
    
    int getNextIntFromFile()
    {
        int val;
        fscanf(seeds, "%d", &val);
        return val;
    }
};

void wrongArgs(int argc, char** argv)
{
        printf("Usage: %s [prng name] [number of strings | path to seeds] [log2 of length >= 6]\n", argv[0]);
        exit(0);
}

shared_ptr<PRNG> getPRNG(char* name)
{
    if (strcmp(name, "z_czapy") == 0)
    {
        return shared_ptr<PRNG>(new LCG(1e9, 1234, 3, 8));
    }
    else if (strcmp(name, "Rand") == 0)
    {
        return shared_ptr<PRNG>(new LCG(2147483648LL, 1103515245, 12345, 31));
    }
    else if (strcmp(name, "Rand0") == 0)
    {
        return shared_ptr<PRNG>(new LCG(2147483648LL, 1103515245, 12345, 8));
    }
    else if (strcmp(name, "Rand1") == 0)
    {
        return shared_ptr<PRNG>(
            new SomeBits(
                shared_ptr<PRNG>(new LCG(2147483648LL, 1103515245, 12345, 31)),
                15, 8
            ) );
    }
    else if (strcmp(name, "Minstd") == 0)
    {
        return shared_ptr<PRNG>(new LCG(2147483647, 16807, 0, 31));
    }
    else if (strcmp(name, "Minstd0") == 0)
    {
        return shared_ptr<PRNG>(new LCG(2147483647, 16807, 0, 8));
    }
    else if (strcmp(name, "Minstd1") == 0)
    {
        return shared_ptr<PRNG>(
            new SomeBits(
                shared_ptr<PRNG>(new LCG(2147483647, 16807, 0, 31)),
                15, 8
            ) );
    }
    else if (strcmp(name, "CMRG") == 0)
    {
        return shared_ptr<PRNG>(new CMRG());
    }
    else if (strcmp(name, "CMRG0") == 0)
    {
        return shared_ptr<PRNG>(
            new SomeBits(
                shared_ptr<PRNG>(new CMRG()),
                7, 0
            ) );
    }
    else if (strcmp(name, "CMRG1") == 0)
    {
        return shared_ptr<PRNG>(
            new SomeBits(
                shared_ptr<PRNG>(new CMRG()),
                15, 8
            ) );
    }
    else if (strcmp(name, "SBorland") == 0)
    {
        return getShifted(shared_ptr<PRNG>(new BorlandPRNG()), 7);
    }
    else if (strcmp(name, "C_PRG") == 0)
    {
        return shared_ptr<PRNG>(new C_PRG());
    }
    else if (strcmp(name, "SVIS") == 0)
    {
        return getShifted(shared_ptr<PRNG>(new VisualPRNG()), 7);
    }
    else if (strcmp(name, "Mersenne") == 0)
    {
        return shared_ptr<PRNG>(new Mersenne());
    }
    else if (strcmp(name, "RANDU") == 0)
    {
        return shared_ptr<PRNG>(new RandU());
    }
    return shared_ptr<PRNG>();
}

int64 myPow(int64 a, uint32 b)
{
    int64 res = 1;
    for (uint32 i = 0; i < b; ++i)
        res *= a;
    return res;
}

int main(int argc, char** argv)
{
    initPow();
    //printPow();
    
    if (argc != 4)
        wrongArgs(argc, argv);
    
    shared_ptr<PRNG> prng = getPRNG(argv[1]);
    if (!prng)
    {
        printf("Unknown prng: %s\n", argv[1]);
        exit(0);
    }
    int64 nrOfStrings = atoi(argv[2]);
    uint32 logLength = atoi(argv[3]);
    if (logLength < 6)
        wrongArgs(argc, argv);
    int64 length = myPow(2LL, logLength);
    
    GeneratorInvoker gi(prng);
    if (nrOfStrings <= 0)
    {
        gi.setPathToSeeds(argv[2]);
        gi.run(length);
    }
    else
    {
        gi.run(nrOfStrings, length);
    }
    return 0;
}
