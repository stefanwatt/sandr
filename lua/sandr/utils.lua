local M = {}

---@param table table
---@param cb function(value: any): boolean
M.index_of = function(table, cb)
    for index, value in ipairs(table) do
        if cb(value) then
            return index
        end
    end
    return nil
end

M.buf_vtext = function()
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
M.map = function(list, cb)
    local result = {}
    for _, value in ipairs(list) do
        table.insert(result, cb(value))
    end
    return result
end

M.flat_map = function(list, cb, ...)
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
M.find = function(list, cb)
    for _, value in ipairs(list) do
        if cb(value) then
            return value
        end
    end
    return nil
end

---Validates args for `throttle()` and  `debounce()`.
local function td_validate(fn, ms)
    vim.validate({
        fn = { fn, "f" },
        ms = {
            ms,
            function(ms)
                return type(ms) == "number" and ms > 0
            end,
            "number > 0",
        },
    })
end

--- Debounces a function on the leading edge. Automatically `schedule_wrap()`s.
---@param fn function Function to debounce
---@param timeout number Timeout in ms
---@return function `debounced function`
---@return uv_timer_t `timer`
---Remember to call `timer:close()` at the end or you will leak memory!
function M.debounce(fn, timeout)
    td_validate(fn, timeout)
    local timer = vim.loop.new_timer()
    local running = false

    local function wrapped_fn(...)
        timer:start(timeout, 0, function()
            running = false
        end)

        if not running then
            running = true
            pcall(vim.schedule_wrap(fn), select(1, ...))
        end
    end
    return wrapped_fn, timer
end

--- @param args table: The unstructured argument list.
--- @return string: text
--- @return number: cursor_pos
--- @return string: prefix
M.parse_ext_cmdline_args = function(args)
    local text = args[1][1][2]
    local cursor_pos = args[2]
    local prefix = args[3]
    return text, cursor_pos, prefix
end

M.substitute_loop_around = function(pattern, replacement)
    local flags = state.getconfig
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
M.set_cmd_line = function(search_term, replace_term, visual, config)
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

return M
