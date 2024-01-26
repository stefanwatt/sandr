local state = require("sandr.state")

---@param start_row number
---@param end_row number
---@param start_col number
---@param pattern string
---@param replacement string
---@param flags string
local function substitute(
    start_row,
    end_row,
    start_col,
    pattern,
    replacement,
    flags
)
    -- Escape the pattern and replacement to avoid issues with special characters
    local escaped_pattern = vim.pesc(pattern)
    local escaped_replacement = vim.pesc(replacement)

    -- Build the modified pattern, which includes the start column logic
    local modified_pattern
    if start_col > 0 then
        -- Match any character up to the start_col, then the actual pattern
        modified_pattern =
            string.format(".\\{%d}\\zs%s", start_col - 1, escaped_pattern)
    else
        -- If start_col is 0 or less, use the pattern as is
        modified_pattern = escaped_pattern
    end

    -- Build and execute the command
    local cmd = string.format(
        "%d,%ds/%s/%s/%s",
        start_row,
        end_row,
        modified_pattern,
        escaped_replacement,
        flags
    )
    pcall(vim.cmd, cmd)
end

local M = {}

function M.toggle()
    --TODO
end

function M.toggle_ignore_case()
    if Config.flags == "gci" then
        state.update_config({ flags = "gc" })
    else
        state.update_config({ flags = "gci" })
    end
end

---@param pattern string
---@param replacement string
---@param starting_match SandrRange
---substitute with loop-around
function M.confirm(pattern, replacement, starting_match)
    --TODO when you press q on the prompt of the first substitute command
    --then it should stop the loop-around
    --but it will execute the second and third still
    local flags = Config.flags
    local current_line = starting_match.start.row
    local last_line = vim.fn.line("$")
    if not current_line or not last_line then
        return
    end
    local start_col = starting_match.start.col

    -- 1. Substitute only on the current line considering the start column
    substitute(
        current_line,
        current_line,
        start_col,
        pattern,
        replacement,
        flags
    )

    -- 2. Substitute from the next line to the end of the file
    if current_line < last_line then
        substitute(current_line + 1, last_line, 0, pattern, replacement, flags)
    end

    -- 3. Substitute from the start of the file to the line before the current match
    if current_line > 1 then
        substitute(1, current_line, 0, pattern, replacement, flags)
    end
end

---@param pattern string
---@param replacement string
function M.replace_all(pattern, replacement)
    local last_line = vim.fn.line("$")
    if not last_line then
        return
    end

    substitute(1, last_line, 0, pattern, replacement, "g")
end

return M
