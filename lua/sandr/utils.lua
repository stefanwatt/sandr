local M = {}

--- for some reason vim.fn.setcmdlinepos() doesn't work, but this does
---@param pos number
M.set_cmd_line_pos = function(pos)
    vim.fn.setcmdline(vim.fn.getcmdline(), pos)
end

---@return string?
M.get_cmd_line = function()
    local cmdline = vim.fn.getcmdline()
    if not M.is_substitute_command() then
        return
    end
    return cmdline
end

---@return boolean?
M.is_substitute_command = function()
    local cmdline = vim.fn.getcmdline()
    if not cmdline or cmdline == "" then
        return
    end
    local pattern = "^%%?s/.*/.*/[gci]*$"
    return string.match(cmdline, pattern) ~= nil
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

---@param _cmdline? string
---@return number?, number?, number?
M.get_slash_positions = function(_cmdline)
    local cmdline = _cmdline or M.get_cmd_line()
    if not cmdline then
        return
    end
    local first_slash_pos, second_slash_pos =
        cmdline:find("/"), cmdline:find("/", cmdline:find("/") + 1)
    if not second_slash_pos then
        return
    end
    local third_slash_pos = string.find(cmdline, "/", second_slash_pos + 1)
    return first_slash_pos, second_slash_pos, third_slash_pos
end

---@return "search" | "replace"  | "end" | nil
M.cursor_pos_in_subst_cmd = function()
    local cmdline = M.get_cmd_line()
    if not cmdline then
        return nil
    end
    local cursor_pos = vim.fn.getcmdpos()
    local first_slash_pos, second_slash_pos, third_slash_pos =
        M.get_slash_positions(cmdline)

    if not first_slash_pos or not second_slash_pos then
        return nil
    end

    if cursor_pos > first_slash_pos and cursor_pos <= second_slash_pos then
        return "search"
    elseif
        third_slash_pos
        and cursor_pos > second_slash_pos
        and cursor_pos <= third_slash_pos
    then
        return "replace"
    elseif third_slash_pos and cursor_pos > third_slash_pos then
        return "end"
    else
        return nil
    end
end

---@param term string
M.insert_search_term = function(term)
    local first_slash_pos, second_slash_pos, _ = M.get_slash_positions()
    if not first_slash_pos or not second_slash_pos then
        return
    end
    vim.fn.setcmdline(
        vim.fn.getcmdline():sub(1, first_slash_pos)
            .. term
            .. vim.fn.getcmdline():sub(second_slash_pos)
    )
end

---@param term string
M.insert_replace_term = function(term)
    local _, second_slash_pos, third_slash_pos = M.get_slash_positions()
    if not third_slash_pos or not second_slash_pos then
        return
    end
    vim.fn.setcmdline(
        vim.fn.getcmdline():sub(1, second_slash_pos)
            .. term
            .. vim.fn.getcmdline():sub(third_slash_pos)
    )
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
    local flags = "gc"
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

M.substitute_all = function(pattern, replacement)
    vim.cmd("%s/" .. pattern .. "/" .. replacement .. "/g")
end

return M
