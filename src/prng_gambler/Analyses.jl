module Analyses

export AnalyzeGambler1D

using RandSources
using Gambler
using BitSeqModule

"""
Simple Gambler analyzer. Runs Gambler's ruin process with given @start, 
@limit, @p, @q, @stepFunction, @stepWin, @stepLoss and @stepNone parameters on all
given @randomSources. Then, it counts the number of wins and loses,
total time of all games, average game time.

@return a tuple of form (# of wins, # of loses, total # of games, 
	averaged win/total ratio, total time of all games and the average
	time of one game.
"""
function AnalyzeGambler1D(randomSources, start::Int64, limit::Int64, p, q, 
stepFunction, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
		
	join(a, b) = ([a[1]; b[1]], [a[2]; b[2]])
	
	function just_run(source)
		try
			(t, w) = runGambler(Gambler1D(start, limit, p, q, stepWin, stepLoss, stepNone), stepFunction, source)
			if w
				return (t, [])
			else
				return ([], t)
			end
		catch EOFError
			return ([], [])
		end
	end
	
	(ArrVic, ArrDef) = @parallel (join) for source in randomSources; just_run(source) end
	
	Wins  = length(ArrVic)
	Losses = length(ArrDef)
	TotalTimeVic = sum(ArrVic)
	TotalTimeDef = sum(ArrDef)
	
	Total = Wins + Losses
	TotalTime = TotalTimeVic + TotalTimeDef
	
	AvgTime = TotalTime / Total
	AvgTimeVic = TotalTimeVic / Wins
	AvgTimeDef = TotalTimeDef / Losses
	
	TimeVicVar = @parallel (+) for t in ArrVic; (t - AvgTimeVic)^2; end
	TimeVicVar /= Wins - 1
	TimeDefVar = @parallel (+) for t in ArrDef; (t - AvgTimeDef)^2; end
	TimeDefVar /= Losses - 1
	TimeVar = @parallel (+) for t in [ArrVic; ArrDef]; (t - AvgTime)^2; end
	TimeVar /= Total - 1
	
	return (Wins, Losses, Total, float(Wins / Total), AvgTime, TimeVar, AvgTimeVic, TimeVicVar, AvgTimeDef, TimeDefVar)
end

function EstimateResultsGambler1D(start::Int64, limit::Int64, p, q)
	# Compute the expected probability of winning with the given start, limit, p and q:
	i = start
	N = limit
	
	divident = sum([prod([big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:i]) + 1
	divisor  = sum([prod([big(q(r, N) / p(r, N)) for r in 1:(n-1)]) for n in 2:N]) + 1
	
	rho = divident / divisor
	
	return (rho,)
end

function runTest(runs)
	#
	#  Constant p and q:
	#
	p(i::Int64, N::Int64) = 0.48
	q(i::Int64, N::Int64) = 0.52
	runOnSources(290, 300, p, "0.48", q, "0.52", runs)

	#
	#  Variable p and q:
	#
	p(i::Int64, N::Int64) = (i)//(2*i + 1)
	q(i::Int64, N::Int64) = (i+1)//(2*i + 1)
	runOnSources(200, 300, p, "(i)/(2i+1)", q, "(i+1)/(2i+1)", runs)

	p(i::Int64, N::Int64) =   (i)^3//(2*i^3 + 3*i^2 + 3*i + 1)
	q(i::Int64, N::Int64) = (i+1)^3//(2*i^3 + 3*i^2 + 3*i + 1)
	runOnSources(200, 300, p, "(i)^3/(2*i^3+3*i^2+3*i+1)", q, "(i+1)^3/(2*i^3+3*i^2+3*i+1)", runs)

	p(i::Int64, N::Int64) = i//N
	q(i::Int64, N::Int64) = (N-i)//N
	runOnSources(150, 300, p, "i/N", q, "(N-i)/N", runs)
end

function runOnSources(i, N, p, str_p, q, str_q, runs)	
	(rho,) = EstimateResultsGambler1D(i, N, p, q)
	rndrho = round(Int, rho * runs) // runs
	
	@printf("Expected rho: %f ", float(rho))
	println("($rho) [$rndrho] for p: $str_p, q: $str_q")
	
	# Functions for creating bit source
	bs_from_file(file) = [
		RandSources.bitSeqBitSource(BitSeqModule.fileToBitSeq("seq/R$file$i"))
		for i=1:runs
		]
	
	bs_from_broken(_) = [RandSources.brokenBitSource for i in 1:runs]
	
	bs_from_julia(_) = [RandSources.juliaBitSource for i in 1:runs]
	
	# Functions for creating random source from bit source
	simulations = [
					"BitTracker    " BitTracker;
					"BitSlicer8    " x -> BitSlicer(x, 8);
					"BitSlicerInv8 " x -> BitSlicerInv(x, 8);
					"BitSlicer12   " x -> BitSlicer(x, 12);
					"BitSlicerInv12" x -> BitSlicerInv(x, 12);
					"BitSlicer15   " x -> BitSlicer(x, 15);
					"BitSlicerInv15" x -> BitSlicerInv(x, 15);
					"BitSlicer16   " x -> BitSlicer(x, 16);
					"BitSlicerInv16" x -> BitSlicerInv(x, 16);
					"BitSlicer17   " x -> BitSlicer(x, 17);
					"BitSlicerInv17" x -> BitSlicerInv(x, 17);
				#	"BitSlicer31   " x -> BitSlicer(x, 31);
				#	"BitSlicerInv31" x -> BitSlicerInv(x, 31);
				]
				
	sources = [
			#	"Broken 01010101 " ""            bs_from_broken;
				"Julia Rand(0:1) " ""            bs_from_julia;
				"/dev/urandom    " "/urand/"     bs_from_file;
				"OpenSSL-RNG     " "/openssl/"   bs_from_file;
				"OpenSSL-RC4     " "/rc4/"       bs_from_file;
				"SPRITZ          " "/spritz/"    bs_from_file;
				"VMPC-KSA        " "/vmpc/"      bs_from_file;
				"RC4+            " "/rc4p/"      bs_from_file;
				"AES-128-CTR     " "/aes128ctr/" bs_from_file;
				"AES-192-CTR     " "/aes192ctr/" bs_from_file;
				"AES-256-CTR     " "/aes256ctr/" bs_from_file;
				"C RAND          " "/crand/"     bs_from_file;
				"RANDU LCG       " "/randu/"     bs_from_file;
				"HC128           " "/hc128/"     bs_from_file;
			]
	
	out_file = open("./results.csv", "w")
	write(out_file, "p(i), q(i), N, n, i_0, simulation type, generator, estimated rho(i), simulated rho(i), variance (est), variance (sim), error b, mean time, time variance, mean time to win, time to win variance, mean time to lose, time to lose variance\n")
	
	for bs in 1:size(sources,1), rs in 1:size(simulations,1)
		lbl, file, to_bs = sources[bs,:]
		simulation_type, simulation = simulations[rs,:]
		
		random_sources = pmap(simulation, to_bs(file))
		gc()
		
		analysis = AnalyzeGambler1D(random_sources, i, N, p, q, Gambler.stepRegular)

		wins, loses, total, ratio, timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar = analysis
		rho_variance = (wins * ((1 - rho)^2) + loses * ((0 - rho)^2)) / total
		mean_variance = (wins * ((1 - ratio)^2) + loses * ((0 - ratio)^2)) / (total - 1)

		fdiff = Float32(rho - ratio)
		fvrho = Float32(rho_variance)
		fmrho = Float32(mean_variance)
		write(out_file, join((str_p, str_q, N, runs, i, simulation_type, lbl, rho, ratio, rho_variance, mean_variance, "-", timeavg, timevar, timevicavg, timevicvar, timedefavg, timedefvar), ","), "\n")
		flush(out_file)
		println("$lbl $simulation_type $analysis diff.: $fdiff v_rho: $fvrho v_mean: $fmrho")
	end
	close(out_file)
end

end #module
