module RandSources

export BitTracker

using BitSeqModule

"""
Simple, Julia bit source. Tosses a die using Julia's internal rand
algorithm.
"""
function juliaBitSource() return rand(0:1) == 1 end

"""
Simple, broken bit source.
"""
global brokenBit = 1
function brokenBitSource()
	global brokenBit
	brokenBit *= 53
	brokenBit %= 79
	return (brokenBit % 2 == 0)
end


"""
Bit source returning consecutive bits from a given bit sequence in each
function call.
"""
function bitSeqBitSource(sequence::BitSeq)
	NF =
		function()
			return BitSeqModule.next(sequence) == 1
		end
	return NF
end


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
				bit = bitSource()
				if bit
					IntervalL += Step
					lrange = checkInRanges(IntervalL, ranges)
				else
					IntervalR -= Step
					rrange = checkInRangesRev(IntervalR, ranges)
				end
				Step *= Mul
			end
			return llrange # rrange == lrange from while end condition
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
				bit = bitSource()
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
source as floating-point representation of number from the interval
[0, 1). Based on the number, one of the intervals [0,p), [p, p+q), 
[p+q, 1) is chosen.
"""
function BitSlicer(bitSource, length::Integer)
	NF =
		function(p::Real, q::Real)
			Step = 1//2
			X = 0
			for i in 1:length
				bit = bitSource() 
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


end #module
