local matches = require("sandr.matches")
local HL_GROUP_DEFAULT = "Search"
local HL_GROUP_CURRENT_MATCH = "IncSearch"
local ns = vim.api.nvim_create_namespace("sandr-highlight")

---@param match Sandr.Range
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

local M = {}

---@param bufnr number
function M.clear_highlights(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

---@param current_matches Sandr.Range[]?
---@param current_match Sandr.Range?
---@param bufnr number
function M.highlight_matches(current_matches, current_match, bufnr)
    if not current_matches then
        print("no matches to be highlighted")
        M.clear_highlights(bufnr)
        return
    end
    if not current_match then
        print("must provide current match to highlight")
        M.clear_highlights(bufnr)
        return
    end
    M.clear_highlights(bufnr)
    for _, match in ipairs(current_matches) do
        local hl_group = matches.equals(match, current_match)
                and HL_GROUP_CURRENT_MATCH
            or HL_GROUP_DEFAULT
        apply_highlight(match, bufnr, hl_group)
    end
end

local replacement_preview_ns =
    vim.api.nvim_create_namespace("SandrReplacementPreview")
---@param search_term string
---@param replace_term string
function M.draw_replacement_preview(search_term, replace_term)
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    local current_matches = matches.get_matches(bufnr, search_term)

    vim.api.nvim_buf_clear_namespace(bufnr, replacement_preview_ns, 0, -1)

    for _, match in ipairs(current_matches) do
        local ext_mark_id = tonumber(
            match.start.col
                .. match.start.row
                .. match.finish.col
                .. match.finish.row
        )

        vim.api.nvim_buf_set_extmark(
            bufnr,
            replacement_preview_ns,
            match.start.row - 1,
            match.start.col,
            {
                end_row = match.finish.row - 1,
                end_col = match.finish.col,
                virt_text = { { replace_term, "CurSearch" } },
                virt_text_pos = "inline",
                hl_mode = "replace",
                strict = false,
                conceal = "3",
            }
        )
    end
end
return M
