module RandSources

export BitTracker

using BitSeqModule

function juliaBitSource() return rand(0:1) == 1 end

function bitSeqBitSource(sequence::BitSeq)
	NF =
		function()
			return BitSeqModule.next(sequence) == 1
		end
	return NF
end

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

end #module
