
using BitSeqModule
using MeasureModule
using LilMeasureCreatorModule
using ArcSineMeasureCreatorModule

function main()
    println("Entering main()")
    if (length(ARGS) != 1)
        println("Usage: julia Main.jl [lil|asin]")
        return
    end
    
    partForAS = vcat( (-Inf, 0.0),  [(x, x+0.025) for x in linspace(0, 0.975, 40)], (1.0, Inf) )
    if (ARGS[1] == "lil")
        creator = LilMeasureCreator()
    elseif (ARGS[1] == "asin")
        creator = ArcSineMeasureCreator(partForAS)
    else
        println("Unknown measure type: $(ARGS[1])")
        return
    end
    
    readAllBits(creator)
    
    println("Making measure...")
    measure = makeMeasure(creator, 1)
    ideal = makeIdealMeasure(creator)
    printSummary(measure, ideal)
end


function readAllBits(creator)
    println("Entering readAllBits()")
    
    nrOfStrings = read(STDIN, Int64)
    length = read(STDIN, Int64)
    println("Julia: nrOfStrings = $nrOfStrings\nJulia: length = $length");
    
    checkPoints = [length]
    initCheckPoints(creator, checkPoints)
    
    counter = 0
    for i in 1:nrOfStrings
        data = read(STDIN, Uint32, div(length,32))
        bits = BitSeq(data)
        #println("readAllBits $i")
        addSeq(creator, bits)
        counter = counter + 1
        if (counter % 10 == 0)
            println("Julia: read $counter")
        end
    end    
end

function makeIdealMeasure(creator::LilMeasureCreator)
    cp = creator.checkPoints
    n = creator.nrOfCheckPoints
    makeLilMeasureU(cp[n])
end

function makeIdealMeasure(creator::ArcSineMeasureCreator)
    cp = creator.checkPoints
    n = creator.nrOfCheckPoints
    makeArcSineMeasureU(cp[n], creator.part)
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
