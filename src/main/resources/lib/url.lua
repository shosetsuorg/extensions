local gsub, format, byte, char = string.gsub, string.format, string.byte, string.char

---@return string
---@param str string
local function urldecode(str)
    str = gsub(str, '+', ' ')
    str = gsub(str, '%%(%x%x)', function(h)
        return char(tonumber(h, 16))
    end)
    str = gsub(str, '\r\n', '\n')
    return str
end

---@return string
---@param str string
local function urlencode(str)
    if str then
        str = gsub(str, '\n', '\r\n')
        str = gsub(str, '([^%w-_.~])', function(c)
            return format('%%%02X', byte(c))
        end)
    end
    return str
end

--- Makes a query string from a table.
---@return string
---@param tbl table<string, any|any[]>
---@param url string | nil
local function querystring(tbl, url)
    local fields = {}
    for key, value in pairs(tbl) do
        local keyString = urlencode(tostring(key)) .. "="
        if type(value) == "table" then
            for _, v in ipairs(value) do
                table.insert(fields, keyString .. urlencode(tostring(v)))
            end
        else
            table.insert(fields, keyString .. urlencode(tostring(value)))
        end
    end
    return (url and url.."?" or "")..table.concat(fields, "&")
end

return {
    urldecode = urldecode,
    urlencode = urlencode,
    querystring = querystring,
}