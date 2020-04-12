-- @Author: raceyu
-- @Date:   2020-04-11 15:37:34
-- @Last Modified by:   raceyu
-- @Last Modified time: 2020-04-11 21:51:43

local _M = {}

function _M.myincr(stats, key, value)
    value = value or 1
    local newval, err = stats:incr(key, value)
    if err then
        stats:set(key, value)
    end
end

function _M.join(tb, sep)
    return table.concat(tb, sep)
end

function _M.split(s, p)
    local rt = {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

function _M.format_output(key_list, value, result)
    -- local m = _M.split(tostring(k), '|')
    e = table.remove(key_list, 1)
    if nil == e or '' == e then
        return value
    elseif nil == result[e] then
        result[e] = _M.format_output(key_list, value, {})
    elseif result[e] ~= nil then
        result[e] = _M.format_output(key_list, value, result[e])
    end
    return result
end

return _M
