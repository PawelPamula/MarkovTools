# Unit tests for input.jl

module TestInput
    using FactCheck
    using MarkovTools

    testpath = "test/prng"

    facts("Reading nonexistent file") do
        @fact_throws readbistream(joinpath(testpath, "abc.txt"))
    end

    facts("Reading an empty file") do
        @fact readbitstream(joinpath(testpath, "0b.txt")) => []
    end

    facts("Reading small sequences from a file") do
        @fact readbitstream(joinpath(testpath, "5b.txt")) => [false, true, false, true, true]::Vector{Bool}
        @fact readbitstream(joinpath(testpath, "10b.txt")) => [true, false, true, false, false, false, true, false, false, true]::Vector{Bool}
    end

    FactCheck.exitstatus()
end