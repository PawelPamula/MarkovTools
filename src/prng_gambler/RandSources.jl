module RandSources

export BitTracker,
	   BitSlicer,
	   BitSlicerInv,
	   bitSeqBitSource,
       init, fini, nextbit, rep

using FileSources
using BitSeqModule


abstract BitSource


function init(src::BitSource)
end

function fini(src::BitSource)
end

rep(src::BitSource) = "Generic BitSource"


# -------------------------------------------------------

type JuliaBitSource <: BitSource
end
rep(src::JuliaBitSource) = "Julia rand(0:1) BitSource"

type BrokenBitSource <: BitSource
	brokenBit::Int
	function BrokenBitSource()
		this = new()
		this.brokenBit = 1
		return this
	end
end
rep(src::BrokenBitSource) = "Utterly Broken LCG BitSource"


"""
Simple, Julia bit source. Tosses a die using Julia's internal rand
algorithm.
"""
function nextbit(_::JuliaBitSource) return rand(0:1) == 1 end

"""
Simple, broken bit source.
"""
function nextbit(src::BrokenBitSource)
	src.brokenBit *= 53
	src.brokenBit %= 79
	return (src.brokenBit % 2 == 0)
end


# -------------------------------------------------------

type BitSeqBitSource <: BitSource
	sequence::BitSeq

	function BitSeqBitSource(sequence::BitSeq)
		this = new()
		this.sequence = sequence
		return this
	end
end
rep(src::BitSeqBitSource) = "Generic Bit Sequence BitSource"

"""
Bit source returning consecutive bits from a given bit sequence in each
function call.
"""
function nextbit(src::BitSeqBitSource)
	return BitSeqModule.next(src.sequence) == 1
end

# -------------------------------------------------------

type FileBitSource <: BitSource
	sequence::StreamSource

	function FileBitSource(sequence::StreamSource)
		this = new()
		this.sequence = sequence
		return this
	end
end
function rep(src::FileBitSource)
	filename=src.sequence.filename
	return "File: $filename BitSource"
end


"""
Bit source returning consecutive bits from a given stream source in each
function call.
"""
function nextbit(src::FileBitSource)
	return FileSources.next(src.sequence) == 1
end

function init(src::FileBitSource)
	FileSources.start(src.sequence)
end

function fini(src::FileBitSource)
	FileSources.stop(src.sequence)
end


# -------------------------------------------------------


"""
Check in which of the given intervals, the given point is:
[0, a), [a, b), [b, c)...
 @param value		The value to test
 @param ranges		Array of range delimiters.
"""
function checkInRanges(value::Real, ranges::AbstractArray)
	result = 1;
	for range in ranges
		if value < range
			return result
		end
		result += 1
	end
	return result
end

"""
Check in which of the given intervals, the given point is:
(0, a], (a, b], (b, c]...
 @param value		The value to test
 @param ranges		Array of range delimiters.
"""
function checkInRangesRev(value::Real, ranges::AbstractArray)
	result = 1;
	for range in ranges
		if value <= range
			return result
		end
		result += 1
	end
	return result
end

function bitOutcomeND(X, ranges)
	test = checkInRanges(X, ranges)

	# move to [0...2n-1] range
	test -= 1
	Outcome = test & 1
	Dim = (test >> 1) + 1
	# if Dim > n, return outcome 2
	if Dim > N
		return 0, 2
	else
		return Dim, Outcome
	end
end

"""
Create a BitTracker function-object for given @bitSource.
The tracker interprets the consecutive bits of the bit source as die
tosses and selects one of the intervals [0,p), [p, p+q), [p+q, 1) using
binary search - just like with numerical encoding.
"""
function BitTracker(bitSource)
	NF =
		function(p::Real, q::Real)
			IntervalL = 0 # incl.
			IntervalR = 1 # excl.
			
			pplusq = p + q
			
			T = typeof(pplusq)
			const Mul = T(1//2)
			Step = Mul
			
			# While the whole interval is not within [0, p) or [p, p+q) or [p+q, 1)
			lrange = 1
			ranges = [p, pplusq]
			rrange = checkInRangesRev(IntervalR, ranges)
			while lrange != rrange
				bit = nextbit(bitSource)
				if bit
					IntervalL += Step
					lrange = checkInRanges(IntervalL, ranges)
				else
					IntervalR -= Step
					rrange = checkInRangesRev(IntervalR, ranges)
				end
				Step *= Mul
			end
			return lrange - 1 # rrange == lrange from while end condition
		end
	return NF
end

"""
Create a BitTracker function-object for given @bitSource.
The tracker interprets the consecutive bits of the bit source as die
tosses and selects one of the intervals [0,p_1), [p_1, p_1+q_1), 
[p_1+q_1, p_1+q_1+p_2)... using binary search - just like with numerical encoding.
"""
function BitTrackerND(bitSource)
	NF =
		function(p::AbstractArray{Real}, q::AbstractArray{Real})
			IntervalL = 0 # incl.
			IntervalR = 1 # excl.
			
			N = length(p)

			T = typeof(p[1])
			const Mul = T(1//2)
			Step = Mul

			lrange = 1
			ranges = []
			accu = 0
			for i in 1:N
				np = p[i] + accu
				accu = np
				nq = q[i] + accu
				accu = nq
				ranges = cat(1, ranges, [np, nq])
			end
			rrange = checkInRangesRev(IntervalR, ranges)
			
			# While the whole interval is not within [0, p) or [p, p+q) or [p+q, 1)
			while lrange != rrange
				bit = nextbit(bitSource)
				if bit
					IntervalL += Step
					lrange = checkInRanges(IntervalL, ranges)
				else
					IntervalR -= Step
					rrange = checkInRangesRev(IntervalR, ranges)
				end
				Step *= Mul
			end
			# move to [0...2n-1] range
			lrange = rrange - 1
			Outcome = lrange & 1
			Dim = (lrange >> 1) + 1
			# if Dim > n, return outcome 2
			if Dim > N
				return 0, 2
			else
				return Dim, Outcome
			end
		end
	return NF
end



"""
Create a BitSlicer function-object for given @bitSource.
The tracker interprets the consecutive slices of @length bits of the bit 
source as little-endian floating-point representation of number from the interval
[0, 1). Based on the number, one of the intervals [0,p), [p, p+q), 
[p+q, 1) is chosen.
"""
function BitSlicer(bitSource, length::Integer)
	NF =
		function(p::Real, q::Real)
			Step = 1
			X = 0
			for i in 1:length
				bit = nextbit(bitSource)
				if bit
					X += Step
				end
				Step *= 2
			end

			X = X / Step
			
			if (X < p)
				return 0
			elseif (X >= p && X < (p+q))
				return 1
			else # (X >= (p+q))
				return 2
			end
		end
	return NF
end


"""
Create a BitSlicer function-object for given @bitSource.
The tracker interprets the slices of @length bits of the bit 
source as big-endian floating-point representation of number from the interval
[0, 1). Based on the number, one of the intervals [0,p_1), [p_1, p_1+q_1), 
[p_1+q_1, p_1+q_1+p_2)... is chosen.
"""
function BitSlicerND(bitSource, length::Integer)
	NF =
		function(p::Real, q::Real)
			Step = 1
			X = 0
			for i in 1:length
				bit = nextbit(bitSource)
				if bit
					X += Step
				end
				Step *= 2
			end
			X = X / Step

			ranges = []
			accu = 0
			for i in 1:N
				np = p[i] + accu
				accu = np
				nq = q[i] + accu
				accu = nq
				ranges = cat(1, ranges, [np, nq])
			end
			return bitOutcomeND(X, ranges)
		end
	return NF
end



"""
Create a BitSlicer function-object for given @bitSource.
The tracker interprets the consecutive slices of @length bits of the bit 
source as big-endian floating-point representation of number from the interval
[0, 1). Based on the number, one of the intervals [0,p), [p, p+q), 
[p+q, 1) is chosen.
"""
function BitSlicerInv(bitSource, length::Integer)
	NF =
		function(p::Real, q::Real)
			Step = 1//2
			X = 0
			for i in 1:length
				bit = nextbit(bitSource)
				if bit
					X += Step
				end
				Step *= 1//2
			end
			
			if (X < p)
				return 0
			elseif (X >= p && X < (p+q))
				return 1
			else # (X >= (p+q))
				return 2
			end
		end
	return NF
end

"""
Create a BitSlicer function-object for given @bitSource.
The tracker interprets the slices of @length bits of the bit 
source as big-endian floating-point representation of number from the interval
[0, 1). Based on the number, one of the intervals [0,p_1), [p_1, p_1+q_1), 
[p_1+q_1, p_1+q_1+p_2)... is chosen.
"""
function BitSlicerInvND(bitSource, length::Integer)
	NF =
		function(p::Real, q::Real)
			Step = 1//2
			X = 0
			for i in 1:length
				bit = nextbit(bitSource)
				if bit
					X += Step
				end
				Step *= 1//2
			end

			ranges = []
			accu = 0
			for i in 1:N
				np = p[i] + accu
				accu = np
				nq = q[i] + accu
				accu = nq
				ranges = cat(1, ranges, [np, nq])
			end
			return bitOutcomeND(X, ranges)
		end
	return NF
end

# -----------------------------------------------------------------------------------
# Additional bit sources
# -----------------------------------------------------------------------------------

abstract StatedBitSource <: RandSources.BitSource

# -----------------------------------------------------------------------------------

type KnuthFibonacci <: StatedBitSource
	state::AbstractArray{UInt32}
	word::UInt32
	pos_state::UInt32
	pos_word::UInt32

	bits::UInt32
	function KnuthFibonacci(seed::Integer)
		this = new()
		s = BigInt(seed) << 1 + 1
		this.state = [((s^i) % (2^30)) for i in 1:100]
		this.pos_state = 1
		this.pos_word = 30
		
		this.bits = 30
		for _ in 1:2000
			nextstate(this)
		end
		return this
	end
end
rep(src::KnuthFibonacci) = "Knuth's Fibonacci Generator"

function nextstate(knuth::KnuthFibonacci)
	minus_100 = knuth.state[knuth.pos_state + 1]
	minus_37  = knuth.state[(knuth.pos_state + 100 - 37) % 100 + 1]
	value = (2^30 + minus_100 - minus_37) % (2^30)
	knuth.pos_state += 1
	knuth.state[knuth.pos_state] = value
	knuth.word = value
	if knuth.pos_state >= 100
		knuth.pos_state = 0
	end
end

# -----------------------------------------------------------------------------------

type LCG <: StatedBitSource
	state::UInt64
	word::UInt64
	pos_word::UInt32

	A::UInt64
	B::UInt64

	N::UInt64
	bits::UInt32
	function LCG(seed::Int, A::Int, B::Int, N::Int, bits::Int)
		this = new()
		this.state = seed

		this.A = A
		this.B = B
		this.N = N

		this.bits = bits
		this.pos_word = bits
		
		nextstate(this)

		return this
	end
end
rep(src::LCG) = string("LCG ", src.A, " x + ", src.B, " mod ", src.N)

function nextstate(this::LCG)
	value = (this.A * this.state + this.B) % lcg.N
	this.state = value
	this.word = value
end

# -----------------------------------------------------------------------------------

"""
“Minimal” random number generator of Park and Miller with Bays-Durham shuffle and added
safeguards. Returns a uniform random deviate between 0.0 and 1.0 (exclusive of the endpoint
values). Call with idum a negative integer to initialize; thereafter, do not alter idum between
successive deviates in a sequence. RNMX should approximate the largest floating value that is
less than 1.
"""
type Ran1 <: StatedBitSource
	iv::AbstractArray{UInt32}
	iy::UInt32
	state::Int32

	word::UInt32
	pos_word::UInt32
	
	bits::UInt32

	function Ran1(seed::Integer)

		"""
		#define IA 16807
		#define IM 2147483647
		#define AM (1.0/IM)
		#define IQ 127773
		#define IR 2836
		#define NTAB 32
		#define NDIV (1+(IM-1)/NTAB)
		#define EPS 1.2e-7
		#define RNMX (1.0-EPS)
		"""

		if seed == 0 seed = 1 end
		this = new()
		this.state = (seed % 2^31)

		this.bits = 31
		this.pos_word = 0

		this.iv = [0 for _ in 1:32]
		for i in 40:-1:1
			k = div(this.state, 127773)
			this.state = 16807*(this.state - k*127773) - k*2836
			if (this.state < 0) this.state += 2147483647 end
			if (i <= 32) this.iv[i] = this.state end
		end
		this.iy = this.iv[1]

		return this
	end
end

function nextstate(this::Ran1)
	k = div(this.state, 127773)
	this.state = 16807*(this.state - k*127773) - k*2836
	if (this.state < 0) this.state += 2147483647 end
	j = div(this.iy, 67108864) # j=iy/NDIV;
	this.iy = this.iv[j+1]
	this.iv[j+1] = this.state
	this.word = this.iy
end

# -----------------------------------------------------------------------------------

"""
Long period (> 2 × 1018) random number generator of L’Ecuyer with Bays-Durham shuffle
and added safeguards. Returns a uniform random deviate between 0.0 and 1.0 (exclusive of
the endpoint values). Call with idum a negative integer to initialize; thereafter, do not alter
idum between successive deviates in a sequence. RNMX should approximate the largest floating
value that is less than 1.
"""

type Ran2 <: StatedBitSource
	iv::AbstractArray{UInt32}
	iy::UInt32
	state0::Int32
	state1::Int32

	word::UInt32
	pos_word::UInt32
	
	bits::UInt32

	function Ran2(seed::Integer)

		"""
		#define IM1 2147483563
		#define IM2 2147483399
		#define AM (1.0/IM1)
		#define IMM1 (IM1-1)
		#define IA1 40014
		#define IA2 40692
		#define IQ1 53668
		#define IQ2 52774
		#define IR1 12211
		#define IR2 3791
		#define NTAB 32
		#define NDIV (1+IMM1/NTAB)
		#define EPS 1.2e-7
		#define RNMX (1.0-EPS)
		"""
		
		if (seed == 0) seed = 1 end
		this = new()
		this.state0 = (seed % 2^31)
		this.state1 = this.state0

		this.bits = 31
		this.pos_word = 0

		this.iv = [0 for _ in 1:32]
		for i in 40:-1:1
			k = div(this.state0, 53668)
			this.state0 = 40014*(this.state0 - k*53668) - k*12211
			if (this.state0 < 0) this.state0 += 2147483563 end
			if (i <= 32) this.iv[i] = this.state0 end
		end
		this.iy = this.iv[1]
		
		return this
	end
end

function nextstate(this::Ran2)
	k = div(this.state0, 53668)
	this.state0 = 40014*(this.state0 - k*53668) - k*12211
	if (this.state0 < 0) this.state0 += 2147483563 end

	k = div(this.state1, 52774)
	this.state1 = 40692*(this.state1 - k*52774) - k*3791
	if (this.state1 < 0) this.state1 += 2147483399 end

	j = div(this.iy, 67108864)
	tmp = this.iv[j+1] - this.state1
	if (tmp < 0) tmp += 2147483562 end
	this.iy = tmp
	this.iv[j+1] = this.state0
	this.word = this.iy
end

# -----------------------------------------------------------------------------------

"""
According to Knuth, any large MBIG, and any smaller (but still large) MSEED can be substituted
for the above values.
float ran3(long *idum)
Returns a uniform random deviate between 0.0 and 1.0. Set idum to any negative value to
initialize or reinitialize the sequence.
"""

type Ran3 <: StatedBitSource
	inext::Int32
	inextp::Int32
	
	ma::AbstractArray{Int32}
	state::Int32

	word::UInt32
	pos_word::UInt32
	
	bits::UInt32

	function Ran3(seed::Integer)

		"""
		#define MBIG 1000000000
		#define MSEED 161803398
		#define MZ 0
		#define FAC (1.0/MBIG)
		"""
		MBIG = 2^31
		MSEED = 161803398
		
		if (seed == 0) seed = 1 end
		this = new()
		this.state = (seed % 2^31)

		this.bits = 31
		this.pos_word = 0

		this.ma = [0 for _ in 1:55]

		mj = abs(MSEED - this.state) % MBIG
		this.ma[55] = mj
		mk = 1
		for i in 1:54
			ii = (21*i) % 55
			this.ma[ii] = mk
			mk = mj - mk
			if(mk < 0) mk += MBIG end
			mj = this.ma[ii]
		end
		for k in 1:4
			for i in 1:55
				this.ma[i] -= this.ma[1+(i+30) % 55]
				if (this.ma[i] < 0) this.ma[i] += MBIG end
			end
		end
		
		this.inext  = 0
		this.inextp = 31
		this.state  = 1
		
		return this
	end
end

function nextstate(this::Ran3)
	this.inext  += 1
	this.inextp += 1
	if(this.inext  == 56) this.inext  = 1 end
	if(this.inextp == 56) this.inextp = 1 end
	
	mj = this.ma[this.inext] - this.ma[this.inextp]
	if(mj < 0) mj += (2^31) end
	this.ma[this.inext] = mj
	
	this.word = mj
end

# -----------------------------------------------------------------------------------

using SHA

kdf(r, i, m) = parse(BigInt, SHA.sha256(string(ENV["ADD_BASE"], "#", r + (i * m))), 16)

function bsFromKnuth(arg, runs, i)
	[KnuthFibonacci(kdf(r, i, runs)) for r in 1:runs]
end

function bsFromRan1(arg, runs, i)
	[Ran1(kdf(r, i, runs)) for r in 1:runs]
end

function bsFromRan2(arg, runs, i)
	[Ran2(kdf(r, i, runs)) for r in 1:runs]
end

function bsFromRan3(arg, runs, i)
	[Ran3(kdf(r, i, runs)) for r in 1:runs]
end

function nextbit(src::StatedBitSource)
	if src.pos_word == 0
		src.pos_word = src.bits
		nextstate(src)
	end
	src.pos_word -= 1
	bit = (src.word & 1)
	src.word >>= 1
	return bit == 1
end

end #module

