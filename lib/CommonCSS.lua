-- {"ver":"1.0.0","author":"TechnoJo4"}

-- Collection of common CSS snippets

local tbl = {}

-- abuse of lua's syntax but it looks nice
local function def(key)
    return function(value)
        tbl[key] = value:gsub("[ \n]+", " ")
        return def
    end
end

def

"" [[]]

"table" [[
table {
    background: none;
    margin: 10px auto;
    width: 90%;
    outline: #004b7a solid 3px;
    border-spacing: 3px;
    border-collapse: separate;
}
td {
    padding: 3px;
    background: #004b7a;
}
]]

local all = ""
for _,v in pairs(tbl) do
    all = all .. v
end
tbl.all = all

return tbl
