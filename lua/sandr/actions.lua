local utils = require("sandr.utils")
local state = require("sandr.state")
local matches = require("sandr.matches")
local highlight = require("sandr.highlight")

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
    --TODO update matches and highlights etc
    state.update_config({ ignore_case = not Config.ignore_case })
end

---@param pattern string
---@param replacement string
---@param starting_match Sandr.Range
---substitute with loop-around
function M.confirm(pattern, replacement, starting_match)
    --TODO when you press q or Esc on the prompt of the first substitute command
    --then it should stop the loop-around
    --but it will execute the second and third still
    local flags = Config.ignore_case and "gci" or "gc"
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

---@param value string
function M.search_input_change(value)
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    local new_matches = matches.get_matches(bufnr, value)

    local current_match = matches.get_closest_match_after_cursor(new_matches)
    if not current_match or not new_matches or #new_matches == 0 then
        highlight.clear_highlights(bufnr)
        return
    end
    state.set_matches(new_matches)
    state.set_current_match(current_match)
    highlight.highlight_matches(new_matches, current_match, bufnr)
end

---@param search_term string
---@param replace_term string
function M.replace_input_submit(search_term, replace_term)
    vim.api.nvim_set_current_win(SourceWinId)
    local current_match = state.get_current_match()
    M.confirm(search_term, replace_term, current_match)
end

function M.prev_search_result()
    local current_match = state.get_current_match()
    local current_matches = state.get_matches()
    local prev_match = matches.get_prev_match(current_match, current_matches)
    if not prev_match then
        return
    end
    state.set_current_match(prev_match)
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    highlight.highlight_matches(current_matches, prev_match, bufnr)
    local prev_match_line = prev_match.start.row
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(SourceWinId)
    if not utils.is_range_in_viewport(prev_match_line) then
        utils.center_line(prev_match_line)
    end
    vim.api.nvim_set_current_win(current_win)
end

function M.next_search_result()
    local current_match = state.get_current_match()
    local current_matches = state.get_matches()
    local next_match = matches.get_next_match(current_match, current_matches)
    if not next_match then
        return
    end
    state.set_current_match(next_match)
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    highlight.highlight_matches(current_matches, next_match, bufnr)
    local next_match_line = next_match.start.row
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(SourceWinId)
    if not utils.is_range_in_viewport(next_match_line) then
        utils.center_line(next_match_line)
    end
    vim.api.nvim_set_current_win(current_win)
end

return M
