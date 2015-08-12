
using BitSeqModule
using MeasureModule
using TestInvokerModule
using ResultSetModule
using ResultPresenterModule

function main()
    println("Entering main()")
    
    testType, nrOfCheckPoints, pathToFile = getCommandLineArgs()
    
    nrOfStrings, length = getDataSize()
    println("Julia: nrOfStrings = $nrOfStrings\nJulia: length = $length");
    loglen = convert(Int64, floor(log2(length)))
    println("Julia: typeof(loglen) = $(typeof(loglen))");
    
    checkPoints, checkPointsLabels = makeCheckPoints(nrOfCheckPoints, loglen)
    println("Julia: checkPoints = $checkPoints\nlabels = $checkPointsLabels");
    
    invoker = TestInvoker(getTestFunction(testType), checkPoints, checkPointsLabels)
    file = open(pathToFile, "w")
    setFileHandle(invoker, file)
    readAllBits(invoker, nrOfStrings, length)    
    close(file)
    
    part = makePartition(testType, 42)
    println("All bits read...")
    ideal = getIdealMeasure(testType, part, length)
    pres = ResultPresenter(invoker.results, ideal)
    init(pres, part)
    present(pres)
end

function getCommandLineArgs()
    if (length(ARGS) < 1 || length(ARGS) > 3)
        error("Usage: julia Main.jl [lil|asin] [nrOfCheckPoints] [pathToFile]")
    end
    
    if (length(ARGS) == 1)
        return ARGS[1], 0, "tmp.txt"
    end
    
    nrOfCheckPoints = parse(ARGS[2])
    if (typeof(nrOfCheckPoints) != Int || nrOfCheckPoints < 0)
        error("Usage: julia Main.jl [lil|asin] {nrOfCheckPoints}")
    end
    
    if (length(ARGS) == 2)
        return ARGS[1], nrOfCheckPoints, "tmp.txt"
    end
    
    return ARGS[1], nrOfCheckPoints, ARGS[3]
end


function getDataSize()
    nrOfStrings = read(STDIN, Int64)
    length = read(STDIN, Int64)
    return nrOfStrings, length
end

function makeCheckPoints(nrOfCheckPoints, loglen)
    checkPoints = zeros(Int64, nrOfCheckPoints+1)
    checkPointsLabels = Array(String, nrOfCheckPoints+1)
    for i in 0:nrOfCheckPoints
        checkPoints[i+1] = 2 ^ (loglen - nrOfCheckPoints + i)
        checkPointsLabels[i+1] = "2^$(loglen - nrOfCheckPoints + i)"
    end
    return checkPoints, checkPointsLabels
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

function readAllBits(invoker, nrOfStrings, length)
    println("Entering readAllBits()")
    
    counter = 0
    for i in 1:nrOfStrings
        data = read(STDIN, Uint32, div(length,32))
        bits = BitSeq(data)
        #println("readAllBits $i")
        addSeq(invoker, bits)
        counter = counter + 1
        if (counter % 100 == 0)
            println("Julia: read $counter")
        end
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

function printSummary(measure, ideal)   
    println("Ideal:")
    printMeasure(ideal)
    println("\n\n\Empirical:")
    printMeasure(measure)
    
    tv = distTV(ideal, measure)
    hell = distHell(ideal, measure)
    rms = distRMS(ideal, measure)
    println("\n\ntotal variation = $tv")
    println("hellinger = $hell")
    println("root mean square = $rms")
end


#Profile.init()
#@profile begin
main()
#end
#Profile.print()
