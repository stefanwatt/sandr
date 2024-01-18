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

---@param prompt string
---@param on_submit function(value: string)
---@param on_change function(value: string)
local function get_input_options(prompt, on_submit, on_change)
    return {
        prompt = prompt .. ": ",
        default_value = "",
        on_submit = on_submit,
        on_change = on_change,
    }
end

---@param source_win_id number
---@param on_submit function(value: string)
---@param on_change function(value: string)
---@return nui_popup_options, nui_input_options
M.get_search_input_options = function(source_win_id, on_submit, on_change)
    return get_popup_options(
        SEARCH_DIALOG_TITLE,
        SEARCH_DIALOG_ROW,
        source_win_id
    ),
        get_input_options("Search", on_submit, on_change)
end

---@param source_win_id number
---@param on_submit function(value: string)
---@param on_change function(value: string)
---@return nui_popup_options, nui_input_options
M.get_replace_input_options = function(source_win_id, on_submit, on_change)
    return get_popup_options(
        REPLACE_DIALOG_TITLE,
        REPLACE_DIALOG_ROW,
        source_win_id
    ),
        get_input_options("Replace", on_submit, on_change)
end
return M
