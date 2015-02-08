# Unit tests for permutations.jl
# Format of tests: TBD

module TestPermutations
    using MarkovTools
    using FactCheck # a different unit test framework
    using Base.Test

    # count_fixed_points
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

    facts("Testing count_fixed_points") do
        @fact count_fixed_points([1, 3, 2, 4, 6, 5]) => 2
        @fact count_fixed_points([]) => 0
    end

    # count_cycles
    p1 = []
    @test isequal(count_cycles(p1), 0)

    p1 = [1, 2, 3, 4, 5]
    @test isequal(count_cycles(p1), 5)

    p1 = [2, 1, 3, 5, 4]
    @test isequal(count_cycles(p1), 3)

    facts("Testing count_cycles") do
        @fact count_cycles([2, 3, 4, 5, 6, 7, 8, 1]) => 1
        @fact count_fixed_points([1, 2, 3, 4, 5, 6, 7, 8]) => 8
    end

end
