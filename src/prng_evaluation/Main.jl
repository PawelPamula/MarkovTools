using LilMeasureCreatorModule
using BitSeqModule
using MeasureModule

function echo()
    while (!eof(STDIN))
        line = readline()
        print("Julia! " * line)
    end
end

function main()
    #m = makeLilMeasureU(2^30, defaultPart)
    #printMeasure(m)
    #return
    
    checkPoints = [2^20]
    lmc = LilMeasureCreator(checkPoints)
    
    counter = 0
    while (!eof(STDIN))
        line = readline()
        bits = stringToBitArray(line)
        addSeq(lmc, bits)
        counter = counter + 1
        if (counter % 100 == 0)
            print("$counter\n")
        end
    end
    
    println("Making measure...")
    u = makeMeasure(lmc, 1) 
    printMeasure(u)
    v = makeLilMeasureU(checkPoints[1])
    d = distTV(u, v)
    println("distance = $d")
end

main()
