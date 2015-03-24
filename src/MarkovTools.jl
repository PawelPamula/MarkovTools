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
include("rozwiazanie.jl")
include("rozwiazanie2.jl")
include("spritz.jl")

end # module
