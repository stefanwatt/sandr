local utils = require("sandr.utils")
Matches = {}
CurrentMatch = nil
local M = {}

---@param line string
---@param row number
---@param search_term string
---@return Sandr.Range[]
local function get_matches_of_line(line, row, search_term)
    local matches = {}
    local line_to_search = Config.ignore_case and string.lower(line) or line

    local term_to_search = search_term
    if Config.regex then
        term_to_search =
            term_to_search:gsub("\\([%a])", "%%%1"):gsub("\\%%", "\\")
    end

    term_to_search = Config.ignore_case and string.lower(term_to_search)
        or term_to_search

    -- print("searching for " .. term_to_search .. " in " .. line_to_search)
    -- print(line_to_search:find(term_to_search, 1, not Config.regex))
    local start_pos = 1
    while true do
        local start, finish =
            line_to_search:find(term_to_search, start_pos, not Config.regex)
        if not start then
            break
        end

        local match = {
            start = { col = start - 1, row = row },
            finish = { col = finish, row = row },
        }
        table.insert(matches, match)
        start_pos = finish + 1
    end

    return matches
end

---@param bufnr number
---@param search_term string
---@return Sandr.Range[]
function M.get_matches(bufnr, search_term)
    if not search_term or search_term == "" then
        return {}
    end
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    Matches = utils.flat_map(lines, get_matches_of_line, search_term)
    return Matches
end

---@param matches Sandr.Range[]
---@return Sandr.Range?
function M.get_closest_match_after_cursor(matches)
    local cursor_row, cursor_col =
        unpack(vim.api.nvim_win_get_cursor(SourceWinId))
    local closestMatch = nil -- Store the closest match found after cursor

    -- First, try to find a match after the cursor position
    for _, match in ipairs(matches) do
        local on_line_after = match.start.row > cursor_row
        local on_same_line = match.start.row == cursor_row
        local cursor_on_match = on_same_line
            and match.start.col <= cursor_col
            and match.finish.col >= cursor_col
        local on_same_line_after = not cursor_on_match
            and on_same_line
            and match.start.col > cursor_col

        if on_line_after or cursor_on_match or on_same_line_after then
            closestMatch = match
            break -- Stop the loop if a match is found
        end
    end

    -- If no match is found after cursor, search from the beginning of the file to the cursor
    if not closestMatch then
        for _, match in ipairs(matches) do
            local on_line_before = match.finish.row < cursor_row
            local on_same_line_before = match.finish.row == cursor_row
                and match.finish.col < cursor_col

            if on_line_before or on_same_line_before then
                closestMatch = match
                -- No break here; keep updating closestMatch to the last match before cursor
            end
        end
    end

    return closestMatch
end

--- @param match1 Sandr.Range
--- @param match2 Sandr.Range
function M.equals(match1, match2)
    return match1.start.col == match2.start.col
        and match1.start.row == match2.start.row
        and match1.finish.col == match2.finish.col
        and match1.finish.row == match2.finish.row
end

---@param current_match Sandr.Range
---@param matches Sandr.Range[]
function M.get_next_match(current_match, matches)
    if current_match == nil then
        error("must provide value for current_match")
        return
    end

    local current_index = utils.index_of(matches, function(match)
        return M.equals(match, current_match)
    end)
    if current_index == nil then
        error("couldn't locate match in list of matches")
        return
    end
    return current_index + 1 > #matches and matches[1]
        or matches[current_index + 1]
end

---@param current_match Sandr.Range
---@param matches Sandr.Range[]
function M.get_prev_match(current_match, matches)
    if current_match == nil then
        error("must provide value for current_match")
        return
    end
    local current_index = utils.index_of(matches, function(match)
        return M.equals(match, current_match)
    end)
    if current_index == nil then
        error("couldn't locate match in list of matches")
        return
    end
    return current_index - 1 < 1 and matches[#matches]
        or matches[current_index - 1]
end

---@param match Sandr.Range
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
