module FileSources

export StreamSource,
       reset,
       next,
       start,
       stop

type StreamSource
	filename::AbstractString
	file::IOStream
	
    wordIndex::Int64
    bitIndex::Int64
    tempWord::UInt64

	function StreamSource(filename::AbstractString)
		this = new()
		this.filename = filename

		this.wordIndex = 0
		this.bitIndex = 0
		
		return this
	end
end # FileSource

function start(bits::StreamSource)
	bits.file = open(bits.filename)
	bits.tempWord = read(bits.file, UInt64)
end

function reset(bits::StreamSource)
	bits.wordIndex = 0
	bits.bitIndex = 0
	seekstart(bits.file)
	bits.tempWord = read(bits.file, UInt64)
end

function next(bits::StreamSource)
	res = bits.tempWord & 1
	if (bits.bitIndex < 63)
	    bits.bitIndex = bits.bitIndex + 1
	    bits.tempWord = bits.tempWord >> 1
	else
	    bits.wordIndex = bits.wordIndex + 1
	    bits.bitIndex = 0
	    bits.tempWord = read(bits.file, UInt64)
	end
	return res
end

function stop(bits::StreamSource)
	close(bits.file)
end

end # Module

