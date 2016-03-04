#!/usr/bin/env julia
push!(LOAD_PATH, ".")

using Gambler
using RandSources

function biasedRandomSource() return rand(0:1) <= 0.9 end

function tests()
	# Create a new Gambler2D object
	Ps = [(i, N) -> 0.25, (i, N) -> 0.25]
	Qs = Ps
	G2D = Gambler.GamblerND(2, [10,10], [20,20], Ps, Qs)
	BT = RandSources.BitTrackerND(biasedRandomSource)
	out = Gambler.runGambler(G2D, Gambler.stepRegular, BT)
	println(out)
#			stepWin::AbstractArray{Int64} = [1 for _ in 1:N], 
#			stepLoss::AbstractArray{Int64} = [-1 for _ in 1:N], 
#			stepNone::AbstractArray{Int64} = [0 for _ in 1:N])
end

tests()

