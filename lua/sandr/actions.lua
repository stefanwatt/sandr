local state = require("sandr.state")

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
function M.confirm(pattern, replacement)
    local flags = state.get_config().flags
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

---@param pattern string
---@param replacement string
function M.replace_all(pattern, replacement)
    vim.cmd("%s/" .. pattern .. "/" .. replacement .. "/g")
end

return M
