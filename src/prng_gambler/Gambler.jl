module Gambler

export Gambler1D,
       GamblerND,
       runGambler

type Gambler1D
	
	time::UInt64
	
	value::Int64
	
	limit::Int64
	
	p::Real # step win probability
	q::Real # step loss probability
	
	stepWin::Int64
	stepNone::Int64
	stepLoss::Int64
	
	function Gambler1D(start::Int64, limit::Int64, p::Real, q::Real, stepWin::Int64=1, stepLoss::Int64=-1, stepNone::Int64=0)
		this = new()
		this.time = 0
		this.value = start
		this.limit = limit
		
		this.p = p
		this.q = q
		
		this.stepWin = stepWin
		this.stepLoss = stepLoss
		this.stepNone = stepNone
		
		return this
	end
end #Gambler1D

type GamblerND
	dim::Unsigned
	time::UInt64
	value::AbstractArray{Int64}
	limit::AbstractArray{Int64}
	
	p::AbstractArray{Real} # individual step win probability
	q::AbstractArray{Real} # individual step loss probability
	
	stepWin::AbstractArray{Int64}
	stepNone::AbstractArray{Int64}
	stepLoss::AbstractArray{Int64}
	
	function GamblerND(N::Unsigned, start::Int64, limit::Int64, 
			p::AbstractArray{Real}, q::AbstractArray{Real}, 
			stepWin::AbstractArray{Int64} = [1 for _ in 1:N], 
			stepLoss::AbstractArray{Int64} = [-1 for _ in 1:N], 
			stepNone::AbstractArray{Int64} = [0 for _ in 1:N])
		this = new()
		this.dim = N
		
		this.time = 0
		this.value = start
		this.limit = limit
		
		this.p = p
		this.q = q
		
		this.stepWin = stepWin
		this.stepLoss = stepLoss
		this.stepNone = stepNone
		
		return this
	end
end #Gambler1D

TGambler = Union{Gambler1D, GamblerND}

"""
The random function should return one of the 3 outcomes:
  0: Win  ( random value between [0, p) )
  1: Loss ( random value between [p, p+q) )
  2: None ( random value between [p+q, 1) )
"""
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

"""
Perform one step of regular Gambler's Ruin process.
 @param state		: state of the process
 @param random		: function with interface like simpleRand
 @param returns		: true if process is finished (won or lost), false otherwise
"""
function stepRegular(state::Gambler1D, random)
	Outcome = random(state.p, state.q)
	if Outcome == 0
		state.value += state.stepWin
	elseif Outcome == 1
		state.value += state.stepLoss
	else
		state.value += state.stepNone
	end
	state.time += 1
	return !isFinished(state)
end

"""
# Perform one step of regular N-dimensional Gambler's Ruin process.
 @param state		: state of the process
 @param random		: function with interface like simpleRand
 @param returns		: true if process is finished (won or lost), false otherwise
"""
function stepRegular(state::GamblerND, random)
	for dim in 1:state.dim
		Outcome = random(state.p, state.q)
		if Outcome == 0
			state.value[dim] += state.stepWin[dim]
			break
		elseif Outcome == 1
			state.value[dim] += state.stepLoss[dim]
			break
		end
	end
	state.time += 1
	return !isFinished(state)
end

# returns true if process is either won or lost
function isFinished(state::TGambler)
	return isWon(state) || isLost(state)
end

# returns true if current state.value >= state.limit
function isWon(state::Gambler1D)
	return state.value >= state.limit
end
function isWon(state::GamblerND, dim::Unsigned)
	return state.value[dim] >= state.limit[dim]
end
function isWon(state::GamblerND)
	return all([isWon(state, X) for X in 1:state.dim])
end

# returns true if current state.value <= 0
function isLost(state::Gambler1D)
	return state.value <= 0
end
function isLost(state::GamblerND, dim::Unsigned)
	return state.value[dim] <= 0
end
function isLost(state::GamblerND)
	return any([isLost(state, X) for X in 1:state.dim])
end

"""
Runs Gambler's Ruin process until the outcome is determined
 @param state			: state of the process
 @param stepFunction	: step function, e.g. stepRegular
 @param randomSource	: random source for step function, e.g. simpleRandom
 @return				: pair: (state.time, isWon(state))
"""
function runGambler(state::TGambler, stepFunction, randomSource)
	while !isFinished(state)
		stepFunction(state, randomSource)
	end
	return (state.time, isWon(state))
end

end #module
