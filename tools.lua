local tools


function tools.map(f,list)
    local r = {}
    for k, v in ipairs(list) do
        table.insert(r, f(v))
    end
    return r
end

function tools.enoughCpus(available, ongoing, free)
    if free == 0 then return false end
    if ongoing == 0 then return true end
    if allowedCpus == 0 then return true end
    if allowedCpus > 0 and allowedCpus < 1 then
        return  (ongoing + 1) / available <= allowedCpus
    end
    if allowedCpus >= 1 then
        return ongoing < allowedCpus
    end
    if allowedCpus > -1 then
        return (free - 1) / available <= -allowedCpus
    end
    return free > -allowedCpus
end

function tools.itemKey(item, withLabel)
    local key = item.name .. '$' .. math.floor(item.damage)
    if withLabel then
        --log('using label for', item.label)
        key = key .. '$' .. item.label
    end
    return key
end

function tools.checkCrafting()
    for _, recipe in ipairs(recipes) do
        if checkFuture(recipe) then
            --log('checkCrafting event !')
            event.push('ae2_loop')
            return
        end
    end
end

function tools.checkFuture(recipe)
    if not recipe.crafting then return end

    local canceled, err = recipe.crafting.isCanceled()
    if canceled or err then
        --log('Crafting of ' .. recipe.label .. ' was cancelled')
        recipe.crafting = nil
        recipe.error = err or 'canceled'
        return true
    end

    local done, err = recipe.crafting.isDone()
    if err then error('isDone ' .. err) end
    if done then
        --log('Crafting of ' .. recipe.label .. ' is done')
        recipe.crafting = nil
        return true
    end

    return false
end

function tools.filter(array, predicate)
    local res = {}
    for _, v in ipairs(array) do
        if predicate(v) then table.insert(res, v) end
    end
    return res
end

function tools.contains(haystack, needle)
    if haystack == needle then return true end
    if type(haystack) ~= type(needle) or type(haystack) ~= 'table' then return false end

    for k, v in pairs(needle) do
        if not contains(haystack[k], v) then return false end
    end

    return true
end

return tools