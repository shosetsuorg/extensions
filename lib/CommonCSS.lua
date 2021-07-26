-- {"ver":"1.0.0","author":"TechnoJo4"}

-- Collection of common CSS snippets

local tbl = {}

local function def(key)
    return function(value)
        tbl[key] = value:gsub("[ \n]+", " ")
        return def
    end
end

def

-- originally meant for tables in WuxiaWorld's USAW, but it turns out many
-- websites use these, so it is relevant to move this snippet here
"table" [[
table {
    background: #004b7a;
    margin: 10px auto;
    width: 90%;
    border: none;
    box-shadow: 1px 1px 1px rgba(0, 0, 0, .75);
    border-collapse: separate;
    border-spacing: 2px;
}
]]

"" [[

]]

return tbl



