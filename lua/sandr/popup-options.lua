local M = {}

local SEARCH_DIALOG_TITLE = "Search"
local SEARCH_DIALOG_ROW = 1
local REPLACE_DIALOG_TITLE = "Replace"
local REPLACE_DIALOG_ROW = 4

---@param title string
---@param row number
---@param source_win_id number
---@return nui_popup_options
local function get_popup_options(title, row, source_win_id)
    return {
        enter = false,
        focusable = true,
        border = {
            style = "rounded",
            -- text = {
            --     top = title,
            --     top_align = "center",
            -- },
            padding = {
                top = 0,
                left = 0,
                right = 0,
                bottom = 0,
            },
        },
        relative = {
            type = "win",
            winid = source_win_id,
        },
        position = {
            row = row,
            col = "99%",
        },
        size = {
            width = 25,
            height = 1,
        },
    }
end

---@param source_win_id number
---@return nui_popup_options
M.get_search_popup_options = function(source_win_id)
    return get_popup_options(
        SEARCH_DIALOG_TITLE,
        SEARCH_DIALOG_ROW,
        source_win_id
    )
end

---@param source_win_id number
---@return nui_popup_options
M.get_replace_popup_options = function(source_win_id)
    return get_popup_options(
        REPLACE_DIALOG_TITLE,
        REPLACE_DIALOG_ROW,
        source_win_id
    )
end
return M
