local M = {}

local IGNORE_CASE = { ON = "", OFF = "̸" }
local REGEX = { ON = "", OFF = "̸" }
local PRESERVE_CASE = { ON = "", OFF = "̸" }
local SEARCH_DIALOG_TITLE = "Search"
local SEARCH_DIALOG_ROW = 1
local REPLACE_DIALOG_TITLE = "Replace"
local REPLACE_DIALOG_ROW = 4

---@param top_text? string
---@param bottom_text string
---@param row number
---@param source_win_id number
---@return nui_popup_options
local function get_popup_options(top_text, bottom_text, row, source_win_id)
    return {
        enter = false,
        focusable = true,
        border = {
            text = {
                top = top_text or "",
                top_align = "left",
                bottom = bottom_text,
                bottom_align = "left",
            },
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
            width = "20%",
            height = 1,
        },
    }
end

---@param on_submit function(value: string)
---@param on_change function(value: string)
local function get_input_options(on_submit, on_change)
    return {
        default_value = "",
        on_submit = on_submit,
        on_change = on_change,
    }
end

---@param on_submit function(value: string)
---@param on_change function(value: string)
---@return nui_popup_options, nui_input_options
function M.get_search_input_options(on_submit, on_change)
    local ignore_case = Config.ignore_case and IGNORE_CASE.ON or IGNORE_CASE.OFF
    local preserve_case = Config.preserve_case and PRESERVE_CASE.ON
        or PRESERVE_CASE.OFF
    local regex = Config.regex and REGEX.ON or REGEX.OFF

    local top_text = ignore_case .. " " .. preserve_case .. " " .. regex
    return get_popup_options(
        top_text,
        SEARCH_DIALOG_TITLE,
        SEARCH_DIALOG_ROW,
        SourceWinId
    ),
        get_input_options(on_submit, on_change)
end

---@param on_submit function(value: string)
---@param on_change function(value: string)
---@return nui_popup_options, nui_input_options
function M.get_replace_input_options(on_submit, on_change)
    return get_popup_options(
        nil,
        REPLACE_DIALOG_TITLE,
        REPLACE_DIALOG_ROW,
        SourceWinId
    ),
        get_input_options(on_submit, on_change)
end

return M
