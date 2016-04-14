#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Gambler
using RandSources

#function biasedRandomSource() return rand(0:1) <= 0.9 end
#
#function tests()
#	# Create a new Gambler2D object
#	p(i::Int64, N::Int64) = 0.25
#	Ps = [p, p]
#	Qs = [p, p]
#	G2D = Gambler.GamblerND(2, [10,10], [20,20], Ps, Qs)
#	BT = RandSources.BitTrackerND(biasedRandomSource)
#	out = Gambler.runGambler(G2D, Gambler.stepRegular, BT)
#	println(out)
#			stepWin::AbstractArray{Int64} = [1 for _ in 1:N], 
#			stepLoss::AbstractArray{Int64} = [-1 for _ in 1:N], 
#			stepNone::AbstractArray{Int64} = [0 for _ in 1:N])
#end

#tests()

function t1()
	fs = []
	for i in 1:10
		f(x) = i * x
		push!(fs, f)
	end
	return fs
end

function t2()
	fs = []
	for i in 1:10
		f = (x) -> i * x
		push!(fs, f)
	end
	return fs
end

f1 = t1()
f2 = t2()

for f in f1
	println(f(1))
end

for f in f2
	println(f(1))
end
