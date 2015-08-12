using ResultSetModule
using ResultPresenterModule
using MeasureModule

function main()
    println("Entering main()")
    
    testType, loglen, pathToFile = getCommandLineArgs()
    length = 2^loglen
    
    pair = readdlm("tmp.txt", ';'; header=true)
    rset = ResultSet(vec(pair[2]))
    fillResultSet(rset, pair[1])
    
    part = makePartition(testType, 42)
    length = 1000500100900
    ideal = getIdealMeasure(testType, part, length)
    pres = ResultPresenter(rset, ideal)
    init(pres, part)
    present(pres)
end

function getCommandLineArgs()
    if (length(ARGS) < 2 || length(ARGS) > 3)
        error("Usage: julia ResultReader.jl [lil|asin] [log2 of length] [pathToFile]")
    end
    
    loglen = parse(ARGS[2])
    if (typeof(loglen) != Int || loglen < 0)
        error("Usage: julia Main.jl [lil|asin] [log2 of length]")
    end
    
    if (length(ARGS) == 2)
        return ARGS[1], loglen, "tmp.txt"
    end
    
    return ARGS[1], loglen, ARGS[3]
end

function fillResultSet(rset :: ResultSet, table :: Array{Float64, 2})
    rows, cols = size(table)
    for r in 1:rows
        addResult(rset, vec(table[r,:]))
    end
    return
end

function getTestFunction(testType)
    if (testType == "lil")
        return calcSlilVal
    elseif (testType == "asin")
        return countFracs
    else
        error("Unknown test type: $testType")
    end
end

function makePartition(testType, nrOfParts)
    if (testType == "lil")
        return makePartitionForLil(nrOfParts)
    elseif (testType == "asin")
        return makePartitionForAsin(nrOfParts)
    else
        error("Unknown test type: $testType")
    end
end
    
function getIdealMeasure(testType::String, part::Partition, length::Int64)
    if (testType == "lil")
        return makeIdealLilMeasure(length, part)
    elseif (testType == "asin")
        return makeIdealAsinMeasure(length, part)
    else
        error("Unknown test type: $testType")
    end
end

main()
