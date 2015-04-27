import ProfileView
import BitSeqModule
import MeasureModule
import LilMeasureCreatorModule
import ArcSineMeasureCreatorModule

BSM = BitSeqModule
MM  = MeasureModule
LMC = LilMeasureCreatorModule
ASMC = ArcSineMeasureCreatorModule

function echo()
    while (!eof(STDIN))
        line = readline()
        print("Julia! " * line)
    end
end

function main()
    nrOfStrings = read(STDIN, Int64)
    length = read(STDIN, Int64)
    println("Julia: nrOfStrings = $nrOfStrings\nJulia: length = $length");
    
    println("Entering main()")
    
    checkPoints = [length]
    lmc = LMC.LilMeasureCreator(checkPoints)
    
    partForAS = vcat( (-Inf, 0.0),  [(x, x+0.025) for x in linspace(0, 0.975, 40)], (1.0, Inf) )
    asmc = ASMC.ArcSineMeasureCreator(checkPoints, partForAS)
    
    counter = 0
    for i in 1:nrOfStrings
        data = read(STDIN, Uint32, div(length,32))
        bits = BSM.BitSeq(data)
        LMC.addSeq(lmc, bits)
        ASMC.addSeq(asmc, bits)
        counter = counter + 1
        if (counter % 10 == 0)
            println("Julia: read $counter")
        end
    end
    
    println("Making LIL measure...")
    lilEmpirical = LMC.makeMeasure(lmc, 1)
    lilIdeal = LMC.makeLilMeasureU(checkPoints[1])
    println("Lil Ideal:")
    MM.printMeasure(lilIdeal)
    println("\n\n\nLil Empirical:")
    MM.printMeasure(lilEmpirical)
    
    println("\n\n\nMaking ASine measure...")
    asEmpirical = ASMC.makeMeasure(asmc, 1)
    asIdeal = ASMC.makeArcSineMeasureU(checkPoints[1], partForAS)
    println("ASine Ideal:")
    MM.printMeasure(asIdeal)
    println("\n\n\nASine Empirical:")
    MM.printMeasure(asEmpirical)
    
    #MM.makeHistogram(asEmpirical)
    
    tv_lil = MM.distTV(lilIdeal, lilEmpirical)
    hell_lil = MM.distHell(lilIdeal, lilEmpirical)
    rms_lil = MM.distRMS(lilIdeal, lilEmpirical)
    tv_as = MM.distTV(asIdeal, asEmpirical)
    hell_as = MM.distHell(asIdeal, asEmpirical)
    rms_as = MM.distRMS(asIdeal, asEmpirical)
    println("\n\ntotal variation for LIL = $tv_lil")
    println("hellinger for LIL = $hell_lil")
    println("root mean square for LIL = $rms_lil")
    println("\n\ntotal variation for AS = $tv_as")
    println("hellinger for AS = $hell_as")
    println("root mean square for AS = $rms_as")
    
end

function newEcho()
    
    nrOfStrings = read(STDIN, Uint64)
    length = read(STDIN, Uint64)
    println("nrOfStrings = $nrOfStrings\nlength = $length");
        a = read(STDIN, Uint32, nrOfStrings)
        println(a)
    for i in 1:nrOfStrings
    end
end

function mainForTextData()
    #m = makeLilMeasureU(2^30, defaultPart)
    #printMeasure(m)
    #return
    println("Entering main()")
    
    length::Int64 = 2^15
    checkPoints = [length]
    lmc = LMC.LilMeasureCreator(checkPoints)
    
    partForAS = vcat( (-Inf, 0.0),  [(x, x+0.025) for x in linspace(0, 0.975, 40)], (1.0, Inf) )
    asmc = ASMC.ArcSineMeasureCreator(checkPoints, partForAS)
    
    
    counter = 0
    while (!eof(STDIN))
        line = readline()
        bits = BSM.stringToBitArray(line)
        #LMC.addSeq(lmc, bits)
        #ASMC.addSeq(asmc, bits)
        counter = counter + 1
        if (counter % 100 == 0)
            print("$counter\n")
        end
    end
    
    println("Making LIL measure...")
    lilEmpirical = LMC.makeMeasure(lmc, 1)
    lilIdeal = LMC.makeLilMeasureU(checkPoints[1])
    println("Lil Ideal:")
    MM.printMeasure(lilIdeal)
    println("\n\n\nLil Empirical:")
    MM.printMeasure(lilEmpirical)
    
    println("\n\n\nMaking ASine measure...")
    asEmpirical = ASMC.makeMeasure(asmc, 1)
    asIdeal = ASMC.makeArcSineMeasureU(checkPoints[1], partForAS)
    println("ASine Ideal:")
    MM.printMeasure(asIdeal)
    println("\n\n\nASine Empirical:")
    MM.printMeasure(asEmpirical)
    
    tv_lil = MM.distTV(lilIdeal, lilEmpirical)
    hell_lil = MM.distHell(lilIdeal, lilEmpirical)
    rms_lil = MM.distRMS(lilIdeal, lilEmpirical)
    tv_as = MM.distTV(asIdeal, asEmpirical)
    hell_as = MM.distHell(asIdeal, asEmpirical)
    rms_as = MM.distRMS(asIdeal, asEmpirical)
    println("\n\ntotal variation for LIL = $tv_lil")
    println("hellinger for LIL = $hell_lil")
    println("root mean square for LIL = $rms_lil")
    println("\n\ntotal variation for AS = $tv_as")
    println("hellinger for AS = $hell_as")
    println("root mean square for AS = $rms_as")
end

#@profile begin

main()

#end
#Profile.print()
