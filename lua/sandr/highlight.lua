local match_equals = require("sandr.matches").equals
local HL_GROUP_DEFAULT = "Search"
local HL_GROUP_CURRENT_MATCH = "IncSearch"
local ns = vim.api.nvim_create_namespace("sandr-highlight")

---@param match SandrRange
---@param buf_id number
---@param hl_group string
local function apply_highlight(match, buf_id, hl_group)
    if not match then
        return
    end

    vim.api.nvim_buf_add_highlight(
        buf_id,
        ns,
        hl_group,
        match.start.row - 1,
        match.start.col,
        match.finish.col
    )
end

---@param bufnr number
local function clear_highlights(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

local M = {}

M.clear_highlights = clear_highlights
---@param matches SandrRange[]?
---@param current_match SandrRange?
---@param bufnr number
M.highlight_matches = function(matches, current_match, bufnr)
    if not matches then
        print("no matches to be highlighted")
        clear_highlights(bufnr)
        return
    end
    if not current_match then
        print("must provide current match to highlight")
        clear_highlights(bufnr)
        return
    end
    clear_highlights(bufnr)
    for _, match in ipairs(matches) do
        local hl_group = match_equals(match, current_match)
                and HL_GROUP_CURRENT_MATCH
            or HL_GROUP_DEFAULT
        apply_highlight(match, bufnr, hl_group)
    end
end

return M
