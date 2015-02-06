module MarkovTools

export 
    #functions
    count_fixed_points,
    count_cycles,

    readbitstream,

    min,
    min2

include("permutations.jl")
include("prng/input.jl")
include("rozwiazanie.jl")

end # module
