module MarkovTools

export 
    #functions
    count_fixed_points,
    count_cycles,
    readbitstream,

    min,
    min2,
    Spritz_Encrypt,
    Spritz_Decrypt
    

include("permutations.jl")
include("prng/input.jl")
include("spritz/spritz.jl")
include("monotonicites/monotonicities.jl")

end # module
