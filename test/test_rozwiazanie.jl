using MarkovTools
using Base.Test

@test isequal(min(1, 2), 1)

@test isequal(min(0, 0), 0)
