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

#function main()
    #m = makeLilMeasureU(2^30, defaultPart)
    #printMeasure(m)
    #return
    println("Entering main()")
    
    checkPoints = [2^10]
    lmc = LMC.LilMeasureCreator(checkPoints)
    
    partForAS = vcat( (-Inf, 0.0),  [(x, x+0.025) for x in linspace(0, 0.975, 40)], (1.0, Inf) )
    asmc = ASMC.ArcSineMeasureCreator(checkPoints, partForAS)
    
    
    counter = 0
    while (!eof(STDIN))
        line = readline()
        bits = BSM.stringToBitArray(line)
        LMC.addSeq(lmc, bits)
        ASMC.addSeq(asmc, bits)
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
    
    d_lil = MM.distTV(lilIdeal, lilEmpirical)
    d_as = MM.distTV(asIdeal, asEmpirical)
    println("\n\n\ndistance for LIL = $d_lil")
    println("distance for ASine = $d_as")
#end

#main()
