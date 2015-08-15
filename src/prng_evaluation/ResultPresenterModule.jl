module ResultPresenterModule

export  ResultPresenter,
        init,
        present
        
using MeasureCreatorModule
using MeasureModule
using ResultSetModule

type ResultPresenter
    results :: ResultSet
    
    idealMeasures :: Array{Measure, 1}
    
    empMeasures :: Array{Measure, 1}
    
    sep :: String
    
    linesep :: String
    
    digits :: Int
    
    function ResultPresenter(rset :: ResultSet, idealMeasures :: Array{Measure, 1})
        this = new()
        this.results = rset
        this.idealMeasures = idealMeasures
        this.sep = "; "
        this.linesep = "\n"
        this.digits = 4
        return this
    end
end # type ResultPresenter

function setDisplay(pres :: ResultPresenter, sep :: String, linesep :: String, digits :: Int)
    pres.sep = "; "
    pres.linesep = "\n"
    pres.digits = digits
end

function init(pres :: ResultPresenter, part :: Partition)
    println("Making measures...")
    n = getNrOfColumns(pres.results)
    pres.empMeasures = Array(Measure, n)
    mc = MeasureCreator(part, pres.results)
    for i in 1:n
        pres.empMeasures[i] = makeMeasure(mc, i)
    end
    return 
end

function displayLine(pres :: ResultPresenter, words)
    wordSize = pres.digits + 3
    balance = 0
    n = length(words)
    for i in 1:n
        balance = balance + wordSize - length(words[i])
        if (balance > 0)
            str = string(repeat(" ", balance), words[i])
            balance = 0
        else
            str = words[i]
        end
        print(str)
        print(pres.sep)
    end
    print(pres.linesep)
end

function displayResultSet(pres :: ResultPresenter, rset :: ResultSet)
    println(rset.header)
    words = ["", map((x) -> string(x), rset.header)]
    println(words)
    displayLine(pres, words)
    rows = getNrOfRows(rset)
    for i in 1:rows
        words = [getRowHeader(rset, i), map((x) -> string(x), round(rset.results[i], pres.digits))]
        displayLine(pres, words)
    end
end

function calcDists(pres :: ResultPresenter, dist :: Function)
    n = getNrOfColumns(pres.results)
    dists = Array(Float64, n)
    for i in 1:n
        dists[i] = dist(pres.empMeasures[i], pres.idealMeasures[i])
    end
    return dists
end

function flip(f :: Function)
    function(a,b)
        f(b,a)
    end
end

function makeTable(pres :: ResultPresenter)
    rset = ResultSet(pres.results.header)
    addResult(rset, calcDists(pres, distTV), "tv")
    addResult(rset, calcDists(pres, distSep), "sep1")
    addResult(rset, calcDists(pres, flip(distSep)), "sep2")
    addResult(rset, calcDists(pres, distHell), "hell")
    addResult(rset, calcDists(pres, distRMS), "rms")
    return rset
end

function present(pres :: ResultPresenter)
    printMeasure(pres.idealMeasures[getNrOfColumns(pres.results)])
    printMeasure(pres.empMeasures[getNrOfColumns(pres.results)])
    rset = makeTable(pres)
    displayResultSet(pres, rset)
end

end # module

