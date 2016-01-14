module RandSources

export BitTracker

using BitSeqModule

"""
Simple, Julia bit source. Tosses a die using Julia's internal rand
algorithm.
"""
function juliaBitSource() return rand(0:1) == 1 end

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
			Step = 1//2
			# While the whole interval is not within [0, p) or [p, p+q) or [p+q, 1)
			while !(IntervalL < p && IntervalR < p) &&
			      !(IntervalL >= p && IntervalR >= p && IntervalL < (p+q) && IntervalR < (p+q)) &&
			      !(IntervalL >= (p+q) && IntervalR >= (p+q))
				bit = bitSource()
				if bit
					IntervalL += Step
				else
					IntervalR -= Step
				end
				Step *= 1//2
			end
			if (IntervalL < p && IntervalR < p)
				return 0
			elseif (IntervalL >= p && IntervalR >= p && IntervalL < (p+q) && IntervalR < (p+q))
				return 1
			else # (IntervalL >= (p+q) && IntervalR >= (p+q))
				return 2
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
