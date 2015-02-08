using MarkovTools
using Base.Test

tests = [
    "test_permutations",
    "prng/test_input"
]

for t in tests
    test_fn = "$t.jl"
    include(test_fn)
end
