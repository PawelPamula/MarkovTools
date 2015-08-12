module ResultPresenterModule

export  ResultPresenter,
        init,
        present
        
using MeasureCreatorModule
using MeasureModule
using ResultSetModule

type ResultPresenter
    results :: ResultSet
    
    idealMeasure :: Measure
    
    empMeasures :: Array{Measure, 1}
    
    sep :: String
    
    linesep :: String
    
    digits :: Int
    
    function ResultPresenter(rset :: ResultSet, idealMeasure :: Measure)
        this = new()
        this.results = rset
        this.idealMeasure = idealMeasure
        this.sep = "; "
        this.linesep = "\n"
        this.digits = 4
        return this
    end
end # type ResultPresenter

function setDisplay(pres :: ResultPresenter, sep :: String, linesep :: String, digits :: Int)
    pres.sep = "; "
    pres.linesep = "\n"
    pres.digits = 4
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

function displayLine(pres :: ResultPresenter, words :: Array{ASCIIString, 1})
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
        dists[i] = dist(pres.empMeasures[i], pres.idealMeasure)
    end
    return dists
end

function makeTable(pres :: ResultPresenter)
    rset = ResultSet(pres.results.header)
    addResult(rset, calcDists(pres, distTV), "tv")
    addResult(rset, calcDists(pres, distHell), "hell")
    addResult(rset, calcDists(pres, distRMS), "rms")
    return rset
end

function present(pres :: ResultPresenter)
    rset = makeTable(pres)
    displayResultSet(pres, rset)
end

end # module

