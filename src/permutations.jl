function count_fixed_points(array)
    result = 0
    for (index, value) in enumerate(array)
        if index == value
            result += 1
        end
    end
    return result
end


function count_cycles(array)
    result = 0
    visited = trues(size(array, 1))
    for (index, value) in enumerate(array)
        if visited[index]
            j = index
            while true
                visited[j] = false
                j = array[j]
                if j == index
                    break
                end
            end
            result += 1
        end
    end
    return result
end