local utils = require("sandr.utils")
local M = {}

---@param line string
---@param row number
---@param search_term string
---@return vim.Range[]
local function get_matches_of_line(line, row, search_term)
    local matches = {}
    local start, finish = string.find(line, search_term)
    while start and finish do
        ---@type vim.Range
        local match = {
            start = {
                col = start - 1,
                row = row,
            },
            ["end"] = {
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
---@return vim.Range[]
function M.get_matches(bufnr, search_term)
    if not search_term or search_term == "" then
        print("must provide search_term")
        return {}
    end
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    return utils.flat_map(lines, get_matches_of_line, search_term)
end

---@param matches vim.Range[]
---@param win_id number
---@return vim.Range?
M.get_closest_match_after_cursor = function(matches, win_id)
    local closest_match = nil
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(win_id))
    for _, match in ipairs(matches) do
        local on_line_after = match.start.row > cursor_row
        local on_same_line = match.start.row == cursor_row
        local cursor_on_match = on_same_line
            and match.start.col <= cursor_col
            and match["end"].col >= cursor_col
        local on_same_line_after = not cursor_on_match
            and on_same_line
            and match.start.col >= cursor_col
        if on_line_after or cursor_on_match or on_same_line_after then
            return match
        end
    end
end

--- @param match1 vim.Range
--- @param match2 vim.Range
function M.equals(match1, match2)
    return match1.start.col == match2.start.col
        and match1.start.row == match2.start.row
        and match1["end"].col == match2["end"].col
        and match1["end"].row == match2["end"].row
end

---@param current_match vim.Range
---@param matches vim.Range[]
function M.get_next_match(current_match, matches)
    if current_match == nil then
        print("must provide value for current_match")
        return
    end

    local current_index = utils.index_of(matches, function(match)
        return M.equals(match, current_match)
    end)
    if current_index == nil then
        print("couldnt locate match in list of matches")
        return
    end
    return current_index + 1 > #matches and matches[1]
        or matches[current_index + 1]
end

return M
