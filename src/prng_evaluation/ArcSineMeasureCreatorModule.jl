module ArcSineMeasureCreatorModule

using MeasureModule
using BitSeqModule

# Function gives distribution of fraction of the time spend "above the line"
# for a truly random bit sequence.
# @param n length of a bit sequence, for now it is ignored and assumed that
#          the distribution is well approximated by arcsine distribution.
# @param a begining of the interval whose measure is calculated
# @param b end of the interval whose measure is calculated
# @return probability that fraction of the time "above the line" is between a and b.
 function arcSineMeasureU(n::Int64, a::Float64, b::Float64)
    if a > b
        return 0
    end
    if (a < 0)
        l = 0
    else
        l = 2 / pi * asin(sqrt(a))
    end
    if (b > 1)
        r = 1
    else
        r = 2 / pi * asin(sqrt(b))
    end
    r - l
 end
 
# Returns a distribution implied by function arcSineMeasureU in a form
# of an object of type Measure.    
# @param n length of bit sequence
# @param part partition on which Measure object is defined
# @return Measure giving distribution of the fraction of the time "above the line".
function makeArcSineMeasureU(n::Int64, part::Partition)
    vals = zeros(Float64, length(part))
    for i in 1:length(part)
        vals[i] = arcSineMeasureU(n, part[i][1], part[i][2])
    end
    Measure(part, vals)
end


# ArcSineMeasureCreator serves to instantiate a probability measure implied
# by bit sequences obtained from a PRG. 
type ArcSineMeasureCreator
    # partition on which created measure is defined
    part::Partition
    
    # number of intervals in a partition (i.e. length of part)
    nrOfParts::Int64
    
    # number of bit sequences used to create a measure
    nrOfSeqs::Int64
    
    # check points specify lengths of prefixes of given bit sequences.
    # Measure may be created using only a prefix, not whole sequence.
    checkPoints::Array{Int64, 1}
    
    # number of check points (i.e. length of checkPoints)
    nrOfCheckPoints::Int64
    
    # Represents empirical function of type
    # (check point index, interval index) -> number of corresponding S_frac values falling to specified interval
    # This array is updated as new sequences appear. It is later used to create a measure.
    buckets::Array{Int64, 2}
    
    
    function ArcSineMeasureCreator(checkPoints_::Array{Int64, 1}, part_::Partition)
        this = new()
        this.checkPoints = copy(checkPoints_)
        this.part = copy(part_)
        this.nrOfSeqs = 0
        this.nrOfParts = length(this.part)
        this.nrOfCheckPoints = length(this.checkPoints)
        this.buckets = Array(Int64, this.nrOfCheckPoints, this.nrOfParts)
        for cp in 1:this.nrOfCheckPoints
            for p in 1:this.nrOfParts
                this.buckets[cp, p] = 0
            end
        end        
        return this
    end
end
        
addSeq = function(amc::ArcSineMeasureCreator, bits::Array{Bool, 1})     
    amc.nrOfSeqs = amc.nrOfSeqs + 1
    n = length(bits)
    fracs = countFracs(bits, amc.checkPoints)            
    for cp_ind in 1:amc.nrOfCheckPoints
        cp = amc.checkPoints[cp_ind]
        addToBucket(amc, cp_ind, fracs[cp_ind])
    end
end

addToBucket = function(amc, cp_ind, frac)
    for i in 1:amc.nrOfParts
        p = amc.part[i]
        if (p[1] <= frac <= p[2])
            amc.buckets[cp_ind, i] = amc.buckets[cp_ind, i] + 1
            return
        end
    end
    error("Appriopriate interval not found!!");
end

makeMeasure = function(amc, cp_ind)
    n = length(amc.part)
    vals = zeros(Float64, n)
    for i in 1:n
        vals[i] = amc.buckets[cp_ind, i] / amc.nrOfSeqs
    end
    Measure(amc.part, vals)
end
   


 
 end #module
 