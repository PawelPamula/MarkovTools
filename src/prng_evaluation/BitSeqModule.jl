module BitSeqModule

export  countOnes,
        countFracs,
        S_star,
        S_lil,
        stringToBitArray

# Literature:
# [1] Y. Wang, T. Nicol, On Statistical Based Testing of Pseudo Random
#     Sequences and Experiments wiht PHP and Debian OpenSSL, 2014

# Counts number of ones in a bitstring.
# @param bits sequence (array) of bits
# @return number of ones in that sequence
function countOnes(bits::Array{Bool, 1})
    n = length(bits)
    s = 0
    for i in 1:n
        if bits[i]
            s = s + 1
        end
    end
    s
end

# Counts number of ones in a bitstring in given checkpoints.
# Checkpoints are lengths of prefixes in which ones should
# be counted.
# @param bits sequence (array) of bits
# @param checkPoints check points as an array of ascending integers
# @return number of of ones in each check points, as an array of
#         of integers of the same length as checkpoints
function countOnes(bits::Array{Bool, 1}, checkPoints::Array{Int64, 1})
    n = length(bits)
    nrOfCheckPoints = length(checkPoints)
    if (n < checkPoints[nrOfCheckPoints])
        error("countOnes: given bit sequence is to short.\nLast " *
              "checkpoint equals $(checkPoints[nrOfCheckPoints]) while sequence is of length $n")
    end
    ones = Array(Int64, nrOfCheckPoints)
    ones[1] = 0
    cp = checkPoints[1]
    cp_ind = 1
    for i in 1:n
        if bits[i]
            ones[cp_ind] = ones[cp_ind] + 1
        end
        if (i >= cp)
            cp_ind = cp_ind + 1
            if (cp_ind <= nrOfCheckPoints)
                cp = checkPoints[cp_ind]
                ones[cp_ind] = ones[cp_ind-1]
            else
                break
            end
        end
    end
    ones
end 

# Counts fraction of time "above the line" for each checkpoint.
function countFracs(bits::Array{Bool, 1}, checkPoints::Array{Int64, 1})
    n = length(bits)
    nrOfCheckPoints = length(checkPoints)
    if (n < checkPoints[nrOfCheckPoints])
        error("countFracs: given bit sequence is to short.\nLast " *
              "checkpoint equals $(checkPoints[nrOfCheckPoints]) while sequence is of length $n")
    end
    fracs = Array(Float64, nrOfCheckPoints)
    prevBalance = 0
    balance = 0
    aboveTheLine = 0
    cp = checkPoints[1]
    cp_ind = 1
    for i in 1:n
        prevBalance = balance
        balance = balance + (bits[i] ? 1 : -1)
        if (prevBalance > 0 || balance > 0)
            aboveTheLine = aboveTheLine + 1
        end
        if (i >= cp)
            fracs[cp_ind] = aboveTheLine / cp
            cp_ind = cp_ind + 1
            
            if (cp_ind <= nrOfCheckPoints)
                cp = checkPoints[cp_ind]
            else
                break
            end
        end
    end
    fracs
end 


# Calculates values S* as defined in [1].
# @param n length of a bitstring
# @param ones number of ones in a bitstring
# @return value S*
function S_star(n::Int64, ones::Int64)
    (2*ones - n) / sqrt(n)
end

# Calculates values S_lil as defined in [1].
# @param n length of a bitstring
# @param ones number of ones in a bitstring
# @return value S_lil
function S_lil(n::Int64, ones::Int64)
    S_star(n, ones) / sqrt(2 * log(log(n)))
end

# Checks whether given character is a white space.
# @param c character to check
# @return true if and only if given character is a white space.
function isWhite(c::Char)
    return c == ' ' || c == '\n' || c == '\t' || c == '\r';
end

# Converts a string into 0-1 sequence of length.
# Trailing (and ONLY trailing) whitespaces are omitted.
# Every '0' is converted to 0, and every other character is converted to 1.
# @param str string to be converted
# @return bit sequence as a Bool Array
function stringToBitArray(str::String)
    l = length(str)
    while (l > 0 && isWhite(str[l]))
        l = l-1
    end
    arr = Array(Bool, l)
    for i in 1:l
        if (str[i] == '0')
            arr[i] = 0
        else
            arr[i] = 1
        end
    end
    return arr
end
   
end # module
