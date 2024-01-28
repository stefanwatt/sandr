local M = {}

---@param table table
---@param cb function(value: any): boolean
function M.index_of(table, cb)
    for index, value in ipairs(table) do
        if cb(value) then
            return index
        end
    end
    return nil
end

function M.buf_vtext()
    local a_orig = vim.fn.getreg("a")
    local mode = vim.fn.mode()
    if mode ~= "v" and mode ~= "V" then
        vim.cmd([[normal! gv]])
    end
    vim.cmd([[silent! normal! "aygv]])
    local text = vim.fn.getreg("a")
    vim.fn.setreg("a", a_orig)
    return tostring(text)
end

function M.flat_map(list, cb, ...)
    local result = {}
    local index = 1
    for _, value in ipairs(list) do
        local mapped = cb(value, index, ...)
        for _, mapped_value in ipairs(mapped) do
            table.insert(result, mapped_value)
        end
        index = index + 1
    end
    return result
end

---@generic T
---@param list `T`[]
---@param cb function(value: `T`): `T`
---@return `T` | nil
function M.find(list, cb)
    for _, value in ipairs(list) do
        if cb(value) then
            return value
        end
    end
    return nil
end

---@param line number
function M.is_range_in_viewport(line)
    local top_line = vim.fn.line("w0")
    local bot_line = vim.fn.line("w$")
    local in_vp = line >= top_line and line <= bot_line
    if in_vp then
        print(
            "line #"
                .. line
                .. " IS between line#"
                .. top_line
                .. " and line#"
                .. bot_line
        )
    else
        print(
            "line #"
                .. line
                .. " IS NOT between line#"
                .. top_line
                .. " and line#"
                .. bot_line
        )
    end
    return in_vp
end

---@param line number
function M.center_line(line)
    vim.api.nvim_win_set_cursor(0, { line, 0 }) -- Set cursor to the line of the match
    vim.cmd("normal zz") -- Center the window view on the cursor line
end
---@param input string
function M.escape_for_regex(input)
    local escaped_str = string.gsub(input, "([\\.\\*\\[\\^\\$~])", "\\%1")
    return escaped_str
end

return M
