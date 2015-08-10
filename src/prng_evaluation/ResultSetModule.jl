module ResultSetModule

export ResultSet,
       addResult,
       getNrOfRows,
       getNrOfColumns,
       getHeader,
       getColumn
       
type ResultSet
    header::Vector{Any}
    
    nrOfColumns::Int64
    
    nrOfRows::Int64
    
    results::Vector{Vector{Float64}}

    function ResultSet(header)
        this = new()
        this.header = header
        this.results = []
        this.nrOfColumns = length(header)
        this.nrOfRows = 0
        return this
    end
end #type ResultSet

function addResult(rset::ResultSet, row::Vector{Float64})
    if (length(row) != rset.nrOfColumns)
        error("addResult :: Number of check points in ResultSet: $(rset.nrOfColumns), length of result vector: $(length(row))")
    end
    push!(rset.results, row)
    rset.nrOfRows = rset.nrOfRows + 1
end

function getNrOfRows(resset::ResultSet)
    return resset.nrOfRows
end

function getNrOfColumns(resset::ResultSet)
    return resset.nrOfColumns
end


function getHeader(resset::ResultSet, nr::Int64)
    return resset.header[nr]
end


function getColumn(resset::ResultSet, column::Int64)
    println("getColumn")
    n = resset.nrOfRows
    res = Array(Float64, n)
    for i in 1:n
        res[i] = resset.results[i][column]
    end
    return res
end

end #module

