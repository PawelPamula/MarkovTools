using MarkovTools
using Base.Test

tests = [
    "test_permutations",
    "prng/test_input"
]

if haskey(ENV, "JL_LOAD_PATH")
    push!(LOAD_PATH, ENV["test/pnrg"])
end

for t in tests
    test_fn = "$t.jl"
    include(test_fn)
end