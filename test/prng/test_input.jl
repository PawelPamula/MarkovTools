# Unit tests for input.jl

module TestInput
    using FactCheck
    using MarkovTools
    using Base

    test_folder = dirname(Base.source_path())

    facts("Reading nonexistent file") do
        @fact_throws readbistream(joinpath(test_folder, "abc.txt"))
    end

    facts("Reading an empty file") do
        @fact readbitstream(joinpath(test_folder, "0b.txt")) => []
    end

    facts("Reading small sequences from a file") do
        @fact readbitstream(joinpath(test_folder, "5b.txt")) => [false, true, false, true, true]::Vector{Bool}
        @fact readbitstream(joinpath(test_folder, "10b.txt")) => [true, false, true, false, false, false, true, false, false, true]::Vector{Bool}
    end

    FactCheck.exitstatus()
end
