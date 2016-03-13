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


end #module

