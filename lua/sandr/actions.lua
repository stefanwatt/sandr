local utils = require("sandr.utils")
local matches = require("sandr.matches")
local highlight = require("sandr.highlight")

function _G.preserve_case_replace(search_term, replace_term)
    if search_term:find("^%u") then
        return replace_term:sub(1, 1):upper() .. replace_term:sub(2):lower()
    else
        return replace_term:lower()
    end
end

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
    local final_pattern = Config.regex and pattern
        or utils.escape_for_regex(pattern)

    if start_row == end_row and start_col > 0 then
        -- For the first line, create a pattern that starts matching after start_col
        local before_pattern = string.format(".\\{%d}", start_col) -- Match any character up to start_col
        final_pattern = string.format(
            "\\%%(%s\\)\\@<=\\%%(%s\\)",
            before_pattern,
            final_pattern
        )
    end

    local final_replacement = Config.preserve_case
            and ("\\=v:lua.preserve_case_replace(submatch(0), '" .. replacement .. "')")
        or replacement

    local cmd = string.format(
        "%d,%ds/%s/%s/%s",
        start_row,
        end_row,
        final_pattern,
        final_replacement,
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
    -- print("config=" .. vim.inspect(Config))
    -- local updated = Config.ignore_case and false or true
    -- print("actions: updated=" .. tostring(updated))
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
    CurrentMatch = current_match
    highlight.highlight_matches(new_matches, current_match, bufnr)
end

---@param search_term string
---@param replace_term string
function M.replace_input_change(search_term, replace_term)
    if not Config.replacement_preview then
        return
    end
    highlight.draw_replacement_preview(search_term, replace_term)
end

---@param pattern string
---@param replacement string
function M.replace_input_submit(pattern, replacement)
    --TODO when you press q or Esc on the prompt of the first substitute command
    --then it should stop the loop-around
    --but it will execute the second and third still
    vim.api.nvim_set_current_win(SourceWinId)
    local flags = Config.ignore_case and "gci" or "gcI"
    local current_line = CurrentMatch.start.row
    local last_line = vim.fn.line("$")
    if not current_line or not last_line then
        return
    end
    local start_col = CurrentMatch.start.col

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

function M.prev_search_result()
    local prev_match = matches.get_prev_match(CurrentMatch, Matches)
    if not prev_match then
        return
    end
    CurrentMatch = prev_match
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    highlight.highlight_matches(Matches, prev_match, bufnr)
    local prev_match_line = prev_match.start.row
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(SourceWinId)
    if not utils.is_range_in_viewport(prev_match_line) then
        utils.center_line(prev_match_line)
    end
    vim.api.nvim_set_current_win(current_win)
end

function M.next_search_result()
    local next_match = matches.get_next_match(CurrentMatch, Matches)
    if not next_match then
        return
    end
    CurrentMatch = next_match
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    highlight.highlight_matches(Matches, next_match, bufnr)
    local next_match_line = next_match.start.row
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(SourceWinId)
    if not utils.is_range_in_viewport(next_match_line) then
        utils.center_line(next_match_line)
    end
    vim.api.nvim_set_current_win(current_win)
end

return M
