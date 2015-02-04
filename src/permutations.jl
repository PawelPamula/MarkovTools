function count_fixed_points(array)
    result = 0
    for (index, value) in enumerate(array)
        println(index, " ", value)
        if index == value
            result += 1
        end
    end
    return result
end
