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

---@generic T
---@param list `T`[]
---@param cb function(value: `T`): `T`
function M.map(list, cb)
    local result = {}
    for _, value in ipairs(list) do
        table.insert(result, cb(value))
    end
    return result
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

--- @param args table: The unstructured argument list.
--- @return string: text
--- @return number: cursor_pos
--- @return string: prefix
function M.parse_ext_cmdline_args(args)
    local text = args[1][1][2]
    local cursor_pos = args[2]
    local prefix = args[3]
    return text, cursor_pos, prefix
end

function M.substitute_loop_around(pattern, replacement)
    local flags = Config.flags
    local current_line = vim.fn.line(".")
    local last_line = vim.fn.line("$")
    vim.api.nvim_input("<CR>")
    -- Substitute from current line to the end of the file
    vim.cmd(
        current_line
            .. ","
            .. last_line
            .. "s/"
            .. pattern
            .. "/"
            .. replacement
            .. "/"
            .. flags
    )

    -- If the current line is not the first line, run the substitute from the start to the current line
    if current_line > 1 then
        vim.cmd(
            "1,"
                .. (current_line - 1)
                .. "s/"
                .. pattern
                .. "/"
                .. replacement
                .. "/"
                .. flags
        )
    end
end

---@param search_term string
---@param replace_term string
---@param visual boolean
---@param config SandrConfig
function M.set_cmd_line(search_term, replace_term, visual, config)
    local cmdline = config.range
        .. "s/"
        .. search_term
        .. "/"
        .. replace_term
        .. "/"
        .. config.flags
    local _, second_slash_pos, third_slash_pos = M.get_slash_positions(cmdline)
    local cursor_pos = (visual and third_slash_pos or second_slash_pos)
    vim.api.nvim_input("<Esc>:")
    vim.schedule(function()
        vim.fn.setcmdline(cmdline, cursor_pos)
    end)
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

return M
