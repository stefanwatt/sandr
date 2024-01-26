local utils = require("sandr.utils")
local M = {}

---@param line string
---@param row number
---@param search_term string
---@return SandrRange[]
local function get_matches_of_line(line, row, search_term)
    local matches = {}
    local start, finish = string.find(line, search_term)
    while start and finish do
        ---@type SandrRange
        local match = {
            start = {
                col = start - 1,
                row = row,
            },
            finish = {
                col = finish,
                row = row,
            },
        }
        table.insert(matches, match)
        start, finish = string.find(line, search_term, finish + 1)
    end
    return matches
end

---@param bufnr number
---@param search_term string
---@return SandrRange[]
function M.get_matches(bufnr, search_term)
    if not search_term or search_term == "" then
        print("must provide search_term")
        return {}
    end
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    return utils.flat_map(lines, get_matches_of_line, search_term)
end

---@param matches SandrRange[]
---@param win_id number
---@return SandrRange?
function M.get_closest_match_after_cursor(matches, win_id)
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(win_id))
    for _, match in ipairs(matches) do
        local on_line_after = match.start.row > cursor_row
        local on_same_line = match.start.row == cursor_row
        local cursor_on_match = on_same_line
            and match.start.col <= cursor_col
            and match.finish.col >= cursor_col
        local on_same_line_after = not cursor_on_match
            and on_same_line
            and match.start.col >= cursor_col
        if on_line_after or cursor_on_match or on_same_line_after then
            return match
        end
    end
end

--- @param match1 SandrRange
--- @param match2 SandrRange
function M.equals(match1, match2)
    return match1.start.col == match2.start.col
        and match1.start.row == match2.start.row
        and match1.finish.col == match2.finish.col
        and match1.finish.row == match2.finish.row
end

---@param current_match SandrRange
---@param matches SandrRange[]
function M.get_next_match(current_match, matches)
    if current_match == nil then
        print("must provide value for current_match")
        return
    end

    local current_index = utils.index_of(matches, function(match)
        return M.equals(match, current_match)
    end)
    if current_index == nil then
        print("couldn't locate match in list of matches")
        return
    end
    return current_index + 1 > #matches and matches[1]
        or matches[current_index + 1]
end

---@param current_match SandrRange
---@param matches SandrRange[]
function M.get_prev_match(current_match, matches)
    if current_match == nil then
        print("must provide value for current_match")
        return
    end
    local current_index = utils.index_of(matches, function(match)
        return M.equals(match, current_match)
    end)
    if current_index == nil then
        print("couldn't locate match in list of matches")
        return
    end
    return current_index - 1 < 1 and matches[#matches]
        or matches[current_index - 1]
end

---@param match SandrRange
function M.centerViewportOnMatch(match)
    local top_line = vim.fn.line("w0") -- Get the top line of the current window
    local bot_line = vim.fn.line("w$") -- Get the bottom line of the current window
    local match_line = match.start.row

    -- Check if the match is outside the current viewport
    if match_line < top_line or match_line > bot_line then
        -- Center the viewport on the match
        vim.api.nvim_win_set_cursor(0, { match_line, 0 }) -- Set cursor to the line of the match
        vim.cmd("normal zz") -- Center the window view on the cursor line
    end
end

return M
