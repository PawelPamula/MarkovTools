# Unit tests for permutations.jl
# Format of tests: TBD

using MarkovTools
using Base.Test

p1 = []
@test isequal(count_fixed_points(p1), 0)

p1 = [1, 2, 3, 4, 5]
@test isequal(count_fixed_points(p1), 5)

p1 = [5, 3, 1, 2, 4]
@test isequal(count_fixed_points(p1), 0)

p1 = [5, 4, 3, 2, 1]
@test isequal(count_fixed_points(p1), 1)

N = 1e6
p1 = [1:N]
@test isequal(count_fixed_points(p1), N)
