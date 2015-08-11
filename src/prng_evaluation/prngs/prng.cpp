#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>

typedef long long int64;
typedef unsigned long long uint64;
typedef int int32;
typedef unsigned int uint32;

using namespace std;

class PRNG
{
public:
    virtual void setSeed(uint32 seed) = 0;
    virtual uint32 nextInt() = 0;
};

class LCG : public PRNG
{
public:
    const uint32 M;
    const uint64 a, b;
    
    LCG(uint32 M_, uint64 a_, uint64 b_)
        : M(M_)
        , a(a_)
        , b(b_)
    {
    }
    
    void setSeed(uint32 seed)
    {
        this->seed = seed;
    }
    
    uint32 nextInt()
    {
        seed = (a * seed + b) % M;
        return seed;
    }
    
private:
    uint32 seed = 1;
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
    
    uint32 nextInt()
    {
        int64 nextx = xa *  x[(n+1)%3]  -  xb * x[n];
        int64 nexty = ya *  y[(n+2)%3]  -  yb * y[n];
        nextx = mymod(nextx, xm);
        nexty = mymod(nexty, ym);
        x[n] = static_cast<int32>(nextx);
        y[n] = static_cast<int32>(nexty);
        //fprintf(stderr, "GeneratorInvoker::generateString %lld, %lld\n",nextx, nexty);
        //fprintf(stderr, "GeneratorInvoker::generateString %d, %d, %d\n", x[0], x[1], x[2]);
        n = (n + 1)%3;
        return (zm + nextx - nexty) % zm;
    }
    
private:
    int32 x[3], y[3];
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
    
    void shift(int32* t, int32 t0)
    {
        t[2] = t[1];
        t[1] = t[0];
        t[0] = t0;
    }
    
};

class CGEN
{
};

class GeneratorInvoker
{
public:
    GeneratorInvoker() = default;
    
    GeneratorInvoker(shared_ptr<PRNG>& prng_)
        : prng(prng_)
    {
    }
    
    void setPRNG(PRNG& prng)
    {
        this->prng = shared_ptr<PRNG>(&prng);
    }
    
    void setPRNG(shared_ptr<PRNG>& prng)
    {
        this->prng = prng;
    }
    
    void run(int64 nrOfStrings, int64 length)
    {
        fprintf(stderr, "GeneratorInvoker::run(%lld, %lld)\n", nrOfStrings, length);
        freopen (NULL, "wb", stdout);
        fwrite(&nrOfStrings, sizeof(int64), 1, stdout);
        fwrite(&length, sizeof(int64), 1, stdout);
        for (int64 i = 1; i <= nrOfStrings; ++i)
        {
            prng->setSeed(i);
            if (i % 100 == 0)
                fprintf(stderr, "Generator: %lld/%lld\n", i, nrOfStrings);
            generateString(length);
        }
        fclose(stdout);
    }
    
    
private:
    shared_ptr<PRNG> prng;
    
    static char getByte(uint32 n, uint32 byteNr)
    {
        n = n >> (byteNr * 8);
        return static_cast<char>(n & 255);
    }
    
    void generateString(int64 nrOfBits)
    {
        //fprintf(stderr, "GeneratorInvoker::generateString(%lld)\n", nrOfBits);
        int64 nrOfBytes = nrOfBits / 8;
        for (int64 i = 0; i < nrOfBytes; ++i)
        {
            uint32 r = prng->nextInt();
            char c = getByte(r, 1);
            //fprintf(stderr, "GeneratorInvoker::generateString r = %u, c = %hhu\n", r, c);
            fwrite(&c, sizeof(char), 1, stdout);
        }
    }
    
};

void wrongArgs(int argc, char** argv)
{
        printf("Usage: %s [prng name] [number of strings] [log2 of length]\n", argv[0]);
        exit(0);
}

shared_ptr<PRNG> getPRNG(char* name)
{
    if (strcmp(name, "z_czapy") == 0)
    {
        return shared_ptr<PRNG>(new LCG(1e9, 1234, 3));
    }
    else if (strcmp(name, "Rand") == 0)
    {
        return shared_ptr<PRNG>(new LCG(2147483648LL, 1103515245, 12345));
    }
    else if (strcmp(name, "Minstd") == 0)
    {
        return shared_ptr<PRNG>(new LCG(2147483647, 16807, 0));
    }
    else if (strcmp(name, "CMRG") == 0)
    {
        return shared_ptr<PRNG>(new CMRG());
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
    if (argc < 4)
        wrongArgs(argc, argv);
    
    shared_ptr<PRNG> prng = getPRNG(argv[1]);
    if (!prng)
    {
        printf("Unknown prng: %s\n", argv[1]);
        exit(0);
    }
    int64 nrOfStrings = atoi(argv[2]);
    uint32 logLength = atoi(argv[3]);
    if (logLength <= 0 || nrOfStrings <= 0)
        wrongArgs(argc, argv);
    int64 length = myPow(2LL, logLength);
    
    GeneratorInvoker gi(prng);
    gi.run(nrOfStrings, length);
    return 0;
}
