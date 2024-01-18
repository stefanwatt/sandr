local state = require("sandr.state")

---@param start_row number
---@param end_row number
---@param pattern string
---@param replacement string
---@param flags string
local function substitute(start_row, end_row, pattern, replacement, flags)
    local cmd = start_row
        .. ","
        .. end_row
        .. "s/"
        .. pattern
        .. "/"
        .. replacement
        .. "/"
        .. flags
    pcall(vim.cmd, cmd)
end
local M = {}

function M.toggle()
    --TODO
end

function M.toggle_ignore_case()
    local current_config = state.get_config()
    if current_config.flags == "gci" then
        state.update_config({ flags = "gc" })
    else
        state.update_config({ flags = "gci" })
    end
end

---@param pattern string
---@param replacement string
---substitute with loop-around
function M.confirm(pattern, replacement)
    --TODO pcall to catch errors
    local flags = state.get_config().flags
    local current_line = vim.fn.line(".")
    local last_line = vim.fn.line("$")
    if not current_line or not last_line then
        return
    end
    vim.api.nvim_input("<CR>")

    -- Substitute from current line to the end of the file
    substitute(current_line, last_line, pattern, replacement, flags)

    -- If the current line is not the first line, run the substitute from the start to the current line
    if current_line <= 1 then
        return
    end
    substitute(1, current_line - 1, pattern, replacement, flags)
end

---@param pattern string
---@param replacement string
function M.replace_all(pattern, replacement)
    local last_line = vim.fn.line("$")
    if not last_line then
        return
    end

    substitute(1, last_line, pattern, replacement, "g")
end

return M
