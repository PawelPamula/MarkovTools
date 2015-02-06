module MarkovTools

export 
    #functions
    count_fixed_points,
    count_cycles,

    readbitstream

include("permutations.jl")
include("prng/input.jl")

end # module