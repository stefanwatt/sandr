local utils = require("sandr.utils")
local state = require("sandr.state")
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
    -- Conditionally escape the pattern and replacement based on Config.regex
    local final_pattern = Config.regex and pattern
        or utils.escape_for_regex(pattern)
    local final_replacement = Config.regex and replacement
        or utils.escape_for_regex(replacement)

    -- Modify the pattern for start_col logic
    local modified_pattern = start_col > 0
            and string.format(".\\{%d}\\zs%s", start_col - 1, final_pattern)
        or final_pattern

    -- Determine the actual replacement text based on Config.preserve_case
    final_replacement = Config.preserve_case
            and ("\\=v:lua.preserve_case_replace(submatch(0), '" .. final_replacement .. "')")
        or final_replacement

    print("finalpattern=" .. final_pattern)
    print("finalreplacement=" .. final_replacement)
    -- Build and execute the substitute command
    local cmd = string.format(
        "%d,%ds/%s/%s/%s",
        start_row,
        end_row,
        modified_pattern,
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
---@param starting_match Sandr.Range
---substitute with loop-around
function M.confirm(pattern, replacement, starting_match)
    --TODO when you press q or Esc on the prompt of the first substitute command
    --then it should stop the loop-around
    --but it will execute the second and third still
    local flags = Config.ignore_case and "gci" or "gcI"
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
function M.replace_input_change(search_term, replace_term)
    if not Config.replacement_preview then
        return
    end
    highlight.draw_replacement_preview(search_term, replace_term)
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
