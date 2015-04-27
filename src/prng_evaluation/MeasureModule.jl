module MeasureModule

#import PyPlot

export  Partition,
        Measure,
        distTV,
        distHell,
        distRMS,
        defaultPart,
        printMeasure,
        makeHistogram

# A partition is represented as an array of float pairs.
# It must have the following form:
# (-inf, a_1), [a_1, a_2), ..., [a_{n-1}, a_n), [a_n, inf)
# It's programmers responsibility to double check that
# an array of float pairs is really a correct partition.
typealias Partition Array{(Float64, Float64), 1}

# Partition of real line which is used in [1].
global defaultPart = vcat( (-Inf, -1.0),
                            [(x, x+0.05) for x in linspace(-1.0, 0.95, 40)],
                            (1.0, Inf) )
                            
# Measure is a class which represents... well, measures.
# Note, however, that this class is limited only to
# measuring intervals from the partition given in a
# constructor.
type Measure
    # partition specifies the intervals whose measure is known
    part::Array{(Float64, Float64), 1}
    # vals give measures of the above intervals
    vals::Array{Float64, 1}

end # type Measure

function myRound(x, n)
    round(x * 10^n) / 10^n
end

function printMeasure(m::Measure)
    n = length(m.part)
    for i in 1:n
        p = m.part[i]
        a = myRound(p[1], 3)
        b = myRound(p[2], 3)
        s = sign(m.vals[i])
        v = myRound(abs(m.vals[i]), 5)
        print("[$a, $b) -> $v\n")
    end
end

function makeHistogram(m::Measure)
    PyPlot.plt.hist(m.vals)
end

# Calculates total variation distance between to probability measures.
# @param u the first probability measure
# @param v the other probability measure
# @return total variation distance between given measures
distTV = function(u::Measure, v::Measure)
    if u.part != v.part
        throw("Measures operate on different partitions")
    end
    n = length(u.part)
    d = 0.0
    for i in 1:n
        x = u.vals[i] - v.vals[i]
        if x > 0
            d = d + x
        end
    end
    return d
end

distHell = function(u::Measure, v::Measure)
    if u.part != v.part
        throw("Measures operate on different partitions")
    end
    n = length(u.part)
    s = 0.0
    for i in 1:n
        x = u.vals[i]
        y = v.vals[i]
        s = s + (sqrt(x) - sqrt(y))^2
    end
    return sqrt(s/2)
end


distRMS = function(u::Measure, v::Measure)
    if u.part != v.part
        throw("Measures operate on different partitions")
    end
    n = length(u.part)
    s = 0.0
    for i in 1:n
        x = u.vals[i]
        y = v.vals[i]
        s = s + (x - y)^2
    end
    return sqrt(s/n)
end

end # module