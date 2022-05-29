-- {"ver":"1.0.1","author":"TechnoJo4"}

-- Collection of common CSS snippets

local tbl = {}

-- abuse of lua's syntax but it looks nice
local function def(key)
    return function(value)
        local function id(c) return c end

        tbl[key] = value
            :gsub("^%s+", "")
            :gsub("%s+$", "")
            :gsub("%s*([;{}])%s*", id)

        return def
    end
end

def

"table" [[
:root {
    --table-color: #007CBA;
}
table {
    background: none !important;
    margin: 10px auto !important;
    width: 90% !important;
    outline: var(--table-color) solid 3px !important;
    border-spacing: 3px !important;
    border-collapse: separate !important;
}
td {
    padding: 3px !important;
    background: var(--table-color) !important;
}
]]

return tbl
