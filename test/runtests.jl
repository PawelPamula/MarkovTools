using MarkovTools
using Base.Test

tests = [
    "test_permutations"
]

for t in tests
    test_fn = "$t.jl"
    include(test_fn)
end