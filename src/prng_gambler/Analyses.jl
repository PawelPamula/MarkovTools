module Analyses

export AnalyzeGambler1D, EstimateResultsGambler1D

using RandSources
using Gambler
using BitSeqModule
using FileSources

"""
Simple Gambler analyzer. Runs Gambler's ruin process with given @start, 
@limit, @p, @q, @stepFunction, @stepWin, @stepLoss and @stepNone parameters on all
given @randomSources. Then, it counts the number of wins and loses,
total time of all games, average game time.

@return a tuple of form (# of wins, # of loses, total # of games, 
	averaged win/total ratio, total time of all games and the average
	time of one game.
"""
function AnalyzeGambler1D(bitSources, simulation, start::Int64, limit::Int64, p, q, 
stepFunction, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
		
	join(a, b) = ([a[1]; b[1]], [a[2]; b[2]])
	
	function just_run(source)
		try
			init(source)
			rand_source = simulation(source)
			(t, w) = runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), stepFunction, rand_source)
			fini(source)
			if w
				return (t, Int64[])
			else
				return (Int64[], t)
			end
		catch EOFError
			srcrep = repr(source)
			print("Encountered EOF when processing $srcrep\n")
			fini(source)
			return (Int64[], Int64[])
		end
	end
	
	(ArrVic, ArrDef) = @parallel (join) for source in bitSources; just_run(source) end
	
	Wins  = length(ArrVic)
	Losses = length(ArrDef)
	TotalTimeVic = sum(ArrVic)
	TotalTimeDef = sum(ArrDef)
	
	Total = Wins + Losses
	TotalTime = TotalTimeVic + TotalTimeDef
	
	AvgTime = TotalTime / Total
	AvgTimeVic = TotalTimeVic / Wins
	AvgTimeDef = TotalTimeDef / Losses
	
	TimeVicVar = length(ArrVic) > 0 ? (@parallel (+) for t in ArrVic; (t - AvgTimeVic)^2; end) : 0
	TimeVicVar /= Wins - 1
	TimeDefVar = length(ArrDef) > 0 ? (@parallel (+) for t in ArrDef; (t - AvgTimeDef)^2; end) : 0
	TimeDefVar /= Losses - 1
	TimeVar = @parallel (+) for t in [ArrVic; ArrDef]; (t - AvgTime)^2; end
	TimeVar /= Total - 1
	
	return (Wins, Losses, Total, float(Wins / Total), AvgTime, TimeVar, AvgTimeVic, TimeVicVar, AvgTimeDef, TimeDefVar)
end

function EstimateResultsGambler1D(start::Int64, limit::Int64, p, q)
	# Compute the expected probability of winning with the given start, limit, p and q:
	i = start
	N = limit

	divident = i>1 ? sum([prod([big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:i]) + 1 : 1
	#divident = sum(BigInt[prod(BigInt[big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:i]) + 1
	divisor  = N>1 ? sum([prod([big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:N]) + 1 : 1
	#divisor  = sum(BigInt[prod(BigInt[big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:N]) + 1
	
	rho = divident / divisor
	
	return rho
end

function filedPQ(filename)
	ps = []
	qs = []
	open(filename) do file
		for line in eachline(file)
			tp = split(line, ", ")
			append!(ps, [float(tp[2])])
			append!(qs, [float(tp[3])])
		end
	end
	pf(r, N) = ps[r]
	qf(r, N) = qs[r]

	return (pf, qf)
end

function runTest(runs)
	out_file = open("./results.csv", "w")
	write(out_file, "p(i), q(i), N, n, i_0, simulation type, generator, estimated rho(i), simulated rho(i), variance (est), variance (sim), error b, mean time, time variance, mean time to win, time to win variance, mean time to lose, time to lose variance\n")
	
	#
	#  Constant p and q:
	#
	p1(i::Int64, N::Int64) = 0.48
	q1(i::Int64, N::Int64) = 0.52
	#runOnSources(out_file, 290, 300, p1, "0.48", q1, "0.52", runs)
	#runOnSources(out_file,  10, 300, q1, "0.52", p1, "0.48", runs)

	#
	#  Variable p and q:
	#
	p2(i::Int64, N::Int64) = (i)//(2*i + 1)
	q2(i::Int64, N::Int64) = (i+1)//(2*i + 1)
	#runOnSources(out_file, 100, 300, p2, "(i)/(2i+1)", q2, "(i+1)/(2i+1)", runs)
	#runOnSources(out_file, 150, 300, p2, "(i)/(2i+1)", q2, "(i+1)/(2i+1)", runs)
	#runOnSources(out_file, 200, 300, p2, "(i)/(2i+1)", q2, "(i+1)/(2i+1)", runs)

	p3(i::Int64, N::Int64) =   (i)^3//(2*i^3 + 3*i^2 + 3*i + 1)
	q3(i::Int64, N::Int64) = (i+1)^3//(2*i^3 + 3*i^2 + 3*i + 1)
	#runOnSources(out_file, 100, 300, p3, "(i)^3/(2*i^3+3*i^2+3*i+1)", q3, "(i+1)^3/(2*i^3+3*i^2+3*i+1)", runs)
	#runOnSources(out_file, 150, 300, p3, "(i)^3/(2*i^3+3*i^2+3*i+1)", q3, "(i+1)^3/(2*i^3+3*i^2+3*i+1)", runs)
	#runOnSources(out_file, 200, 300, p3, "(i)^3/(2*i^3+3*i^2+3*i+1)", q3, "(i+1)^3/(2*i^3+3*i^2+3*i+1)", runs)

	p4(i::Int64, N::Int64) = i//N
	q4(i::Int64, N::Int64) = (N-i)//N
	#runOnSources(out_file, 145, 300, p4, "i/N", q4, "(N-i)/N", runs)
	#runOnSources(out_file, 150, 300, p4, "i/N", q4, "(N-i)/N", runs)
	#runOnSources(out_file, 155, 300, p4, "i/N", q4, "(N-i)/N", runs)

	(p5, q5) = filedPQ("random_p_q_1.csv")
	#runOnSources(out_file, 150, 300, p5, "random(1)", q5, "random(1)", runs)
	(p6, q6) = filedPQ("random_p_q_7.csv")
	#runOnSources(out_file, 50, 300, p6, "random(2)", q6, "random(2)", runs)
	#runOnSources(out_file, 150, 300, p6, "random(2)", q6, "random(2)", runs)

	#
	#  All i in range:
	#
	for i in 7:99
	#	runOnSources(out_file, i, 300, p1, "0.48", q1, "0.52", runs)
	#	runOnSources(out_file, i, 300, p2, "(i)/(2i+1)", q2, "(i+1)/(2i+1)", runs)
	#	runOnSources(out_file, i, 300, p3, "(i)^3/(2*i^3+3*i^2+3*i+1)", q3, "(i+1)^3/(2*i^3+3*i^2+3*i+1)", runs)
		runOnSources(out_file, i, 300, p4, "i/N", q4, "(N-i)/N", runs)
	#	runOnSources(out_file, i, 300, p6, "random(2)", q6, "random(2)", runs)
	end

	close(out_file)
end

function runOnSources(out_file, i, N, p, str_p, q, str_q, runs)
	function generator(cmd, r)
		# byte limit for dynamically generated sources
		limit = 512*1024 #16*1024*1024
		# key derivation function
		kdf = "sha"
		km = r + (i * runs)
		return `bash generator.sh $kdf $cmd $limit $km`
	end

	rho = EstimateResultsGambler1D(i, N, p, q)
	rndrho = round(Int, rho * runs) // runs
	
	@printf("Expected rho: %f ", float(rho))
	println("($rho) [$rndrho] for p: $str_p, q: $str_q")
	
	# Functions for creating bit source
	bs_from_file(file) = [
		#RandSources.BitSeqBitSource(BitSeqModule.fileToBitSeq("seq/R$file$i"))
		RandSources.FileBitSource(FileSources.FileSource("seq/R$file$i"))
		for i=1:runs
		]
	
	bs_from_cmd(cmd) = [
		RandSources.FileBitSource(FileSources.CmdSource(generator(cmd, r)))
		for r=1:runs
		]
	
	bs_from_broken(_) = [RandSources.BrokenBitSource() for i in 1:runs]
	
	bs_from_julia(_) = [RandSources.JuliaBitSource() for i in 1:runs]
	
	# Functions for creating random source from bit source
	simulations = [
					"BitTracker    " BitTracker;
				#	"BitSlicer8    " x -> BitSlicer(x, 8);
				#	"BitSlicerInv8 " x -> BitSlicerInv(x, 8);
				#	"BitSlicer12   " x -> BitSlicer(x, 12);
				#	"BitSlicerInv12" x -> BitSlicerInv(x, 12);
				#	"BitSlicer15   " x -> BitSlicer(x, 15);
				#	"BitSlicerInv15" x -> BitSlicerInv(x, 15);
				#	"BitSlicer16   " x -> BitSlicer(x, 16);
				#	"BitSlicerInv16" x -> BitSlicerInv(x, 16);
				#	"BitSlicer17   " x -> BitSlicer(x, 17);
				#	"BitSlicerInv17" x -> BitSlicerInv(x, 17);
				#	"BitSlicer31   " x -> BitSlicer(x, 31);
				#	"BitSlicerInv31" x -> BitSlicerInv(x, 31);
				]
				
	sources = [
			#	"Broken 01010101 " ""            bs_from_broken;
			#	"Julia Rand(0:1) " ""            bs_from_julia;
			#	"/dev/urandom    " "urandom"     bs_from_cmd;
			#	"OpenSSL-RNG     " "openssl-rng" bs_from_cmd;
			#	"OpenSSL-RC4     " "rc4"         bs_from_cmd;
			#	"SPRITZ          " "spritz"      bs_from_cmd;
			#	"VMPC-KSA        " "vmpc"        bs_from_cmd;
			#	"RC4+            " "rc4p  "      bs_from_cmd;
			#	"AES-128-CTR     " "aes128ctr"   bs_from_cmd;
			#	"AES-192-CTR     " "aes192ctr"   bs_from_cmd;
			#	"AES-256-CTR     " "aes256ctr"   bs_from_cmd;
			#	"C RAND          " "crand"       bs_from_cmd;
				"RANDU LCG       " "randu"       bs_from_cmd;
			#	"HC128           " "hc128"       bs_from_cmd;
			#	"RABBIT          " "rabbit"      bs_from_cmd;
			#	"SALSA20/12      " "salsa20"     bs_from_cmd;
			#	"SOSEMANUK       " "sosemanuk"   bs_from_cmd;
			#	"GRAIN           " "grain"       bs_from_cmd;
			#	"MICKEY          " "mickey"      bs_from_cmd;
			#	"TRIVIUM         " "trivium"     bs_from_cmd;
			#	"F-FCSR          " "ffcsr"       bs_from_cmd;
			#	"Mersenne Twister" "mersenne"    bs_from_cmd;
			]
	
	for bs in 1:size(sources,1), rs in 1:size(simulations,1)
		lbl, file, to_bs = sources[bs,:]
		simulation_type, simulation = simulations[rs,:]
		
		bit_sources    = to_bs(file)
		#gc()
		
		analysis = AnalyzeGambler1D(bit_sources, simulation, i, N, p, q, Gambler.stepRegular)

		wins, loses, total, ratio, timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar = analysis
		rho_variance = (wins * ((1 - rho)^2) + loses * ((0 - rho)^2)) / total
		mean_variance = (wins * ((1 - ratio)^2) + loses * ((0 - ratio)^2)) / (total - 1)

		fdiff = Float32(rho - ratio)
		fvrho = Float32(rho_variance)
		fmrho = Float32(mean_variance)
		write(out_file, join((str_p, str_q, N, runs, i, simulation_type, lbl, float(rho), float(ratio), float(rho_variance), float(mean_variance), "-", timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar), ","), "\n")
		flush(out_file)
		println("$lbl $simulation_type $analysis diff.: $fdiff v_rho: $fvrho v_mean: $fmrho")
	end
end

end #module

