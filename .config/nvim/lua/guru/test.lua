-- This should NOT show a diagnostic (your lua_ls config whitelists `vim`)
print(vim.inspect({ "hello", "world" }))

-- This SHOULD show a diagnostic immediately:
-- undefined global (intentionallxy wrong)
print(unknown_variable)

-- Hover test (put cursor on the next function name and press 'K')
local function add(a, b)
    return a + b
end

local res = add(10, 20)

-- Completion test: type "stri" and trigger completion (no snippets should appear)
local x = "hello"

print(res)

print(x)
