module LilMeasureCreatorModule

export  lilMeasureU,
        makeLilMeasureU,
        LilMeasureCreator,
        addSeq,
        makeMeasure
    
using Distributions
using MeasureModule
using BitSeqModule

# Function corresponding to \mu^U_n from [1].
# @param n length of a bit sequence
# @param a begining of the interval whose measure is calculated
# @param b end of the interval whose measure is calculated
# @return Value \mu^U_n(a, b)
function lilMeasureU(n::Int64, a::Float64, b::Float64)
    N = Normal()
    s = sqrt(2*log(log(n)))
    cdf(N, b*s) - cdf(N, a*s)
end

# Just to ensure results of this implementation are
# consistent with those in [1].
function print_lil_measure_U_table()
    table = Array(Any, 22, 10)
    table[1,1] = ""
    for c in 2:10
        table[1, c] = "2^$(24+c)"
    end
    for r in 2:21
        table[r, 1] = ((r-2)*0.05,(r-1)*0.05)
    end
    table[22, 1] = (1.0, Inf)
    for c in 2:10
        for r in 2:22
            p = table[r, 1]
            table[r, c] = lilMeasureU(2^(c+24), p[1], p[2])
        end
    end
    println(table)
end

    
# Returns \mu^U_n from [1] in a form of an object of type Measure.    
# @param n length of bit sequence
# @param part partition on which Measure object is defined
# @return Measure object corresponding to \mu^U_n
function makeLilMeasureU(n::Int64, part::Partition = defaultPart)
    vals = zeros(Float64, length(part))
    for i in 1:length(part)
        vals[i] = lilMeasureU(n, part[i][1], part[i][2])
    end
    Measure(part, vals)
end


# LilMeasureCreator serves to instantiate a probability measure implied
# by bit sequences obtained from a PRG. 
type LilMeasureCreator
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
    # (check point index, interval index) -> number of corresponding S_lil values falling to specified interval
    # This array is updated as new sequences appear. It is later used to create a measure.
    buckets::Array{Int64, 2}
    
    function LilMeasureCreator(checkPoints_::Array{Int64, 1})
        return LilMeasureCreator(checkPoints_, defaultPart)
    end
    
    function LilMeasureCreator(checkPoints_::Array{Int64, 1}, part_::Partition)
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


        
addSeq = function(lmc::LilMeasureCreator, bits::Array{Bool, 1})     
    lmc.nrOfSeqs = lmc.nrOfSeqs + 1
    n = length(bits)
    ones = countOnes(bits, lmc.checkPoints)            
    for cp_ind in 1:lmc.nrOfCheckPoints
        cp = lmc.checkPoints[cp_ind]
        addToBucket(lmc, cp_ind, S_lil(cp, ones[cp_ind]))
    end
end

addToBucket = function(lmc, cp_ind, val)
    for i in 1:lmc.nrOfParts
        p = lmc.part[i]
        if (p[1] <= val <= p[2])
            lmc.buckets[cp_ind, i] = lmc.buckets[cp_ind, i] + 1
            return
        end
    end
    error("Appriopriate interval not found!!");
end

makeMeasure = function(lmc, cp_ind)
    n = length(lmc.part)
    vals = zeros(Float64, n)
    for i in 1:n
        vals[i] = lmc.buckets[cp_ind, i] / lmc.nrOfSeqs
    end
    Measure(lmc.part, vals)
end
                            
end #module
