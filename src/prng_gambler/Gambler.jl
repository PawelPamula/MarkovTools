module Gambler

export Gambler1D

type Gambler1D
	
	time::UInt64
	
	value::Int64
	
	limit::Int64
	
	p::Real
	q::Real
	
	stepWin::Int64
	stepNone::Int64
	stepLoss::Int64
	
	function Gambler1D(start::Int64, limit::Int64, p::Real, q::Real, stepWin::Int64=1, stepNone::Int64=0, stepLoss::Int64=-1)
		this = new()
		this.time = 0
		this.value = start
		this.limit = limit
		
		this.p = p
		this.q = q
		
		this.stepWin = stepWin
		this.stepNone = stepNone
		this.stepLoss = stepLoss
		
		return this
	end
end #Gambler1D

# The random function should return one of the 3 outcomes:
#  0: Win ( random value between [0, p) )
#  1: None ( random value between [p, p+q) )
#  2: Loss ( random value between [p+q, 1) )
function simpleRand(p::Real, q::Real)
	R = rand() # rand returns random number \in [0, 1)
	if R < p
		return 0
	elseif R < p + q
		return 1
	else
		return 2
	end
end

function stepRegular(state::Gambler1D, random)
	Outcome = random(state.p, state.q)
	if Outcome == 0
		state.value += state.stepWin
	elseif Outcome == 1
		state.value += state.stepNone
	else
		state.value += state.stepLoss
	end
	state.time += 1
	return !isFinished(state)
end

function isFinished(state::Gambler1D)
	if state.value <= 0 || state.value >= state.limit
		return true
	else
		return false
	end
end

function isWon(state::Gambler1D)
	if state.value >= state.limit
		return true
	else
		return false
	end
end

function isLost(state::Gambler1D)
	if state.value <= 0
		return true
	else
		return false
	end
end

function runGambler(state::Gambler1D, stepFunction, randomSource)
	while !isFinished(state)
		stepFunction(state, randomSource)
	end
	return (state.time, isWon(state))
end

end #module
