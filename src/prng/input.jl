import Base.convert

convert(::Type{Vector{Bool}}, string::ASCIIString) = [(ch != '0') for ch in string]

function readbitstream(filename::ASCIIString)
    open(filename, "r") do file
        convert(Vector{Bool}, readall(file))
    end
end