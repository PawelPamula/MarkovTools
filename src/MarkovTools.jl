module MarkovTools

export 
    #functions
    count_fixed_points,
    count_cycles,

    readbitstream,

    min

include("permutations.jl")
include("prng/input.jl")
include("rozwiazanie.jl")

end # module
