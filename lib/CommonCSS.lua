-- {"ver":"1.0.0","author":"TechnoJo4"}

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
    background: none;
    margin: 10px auto;
    width: 90%;
    outline: var(--table-color) solid 3px;
    border-spacing: 3px;
    border-collapse: separate;
}
td {
    padding: 3px;
    background: var(--table-color);
}
]]

return tbl
