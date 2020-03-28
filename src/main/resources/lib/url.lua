-- {"version":"1.0.0","author":"TechnoJo4"}

local gsub, format, byte, char = string.gsub, string.format, string.byte, string.char

---@return string
---@param str string
local function urlDecode(str)
    str = gsub(str, '+', ' ')
    str = gsub(str, '%%(%x%x)', function(h)
        return char(tonumber(h, 16))
    end)
    str = gsub(str, '\r\n', '\n')
    return str
end

---@return string
---@param str string
local function urlEncode(str)
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
        local keyString = urlEncode(tostring(key)) .. "="
        if type(value) == "table" then
            for _, v in ipairs(value) do
                table.insert(fields, keyString .. urlEncode(tostring(v)))
            end
        else
            table.insert(fields, keyString .. urlEncode(tostring(value)))
        end
    end
    return (url and url.."?" or "")..table.concat(fields, "&")
end

return {
    decode = urlDecode,
    encode = urlEncode,
    querystring = querystring,
}