local popup_options = require("sandr.popup-options")

---@class SandrPopup
---@field value? string
---@field mounted boolean
---@field nui_popup? NuiPopup
---@field source_win_id? number
local search_popup = { mounted = false }

local visible = false
local namespace = nil

---@param source_win_id number
local function init_search_popup(source_win_id)
    local _popup_options = popup_options.get_search_popup_options(source_win_id)
    search_popup.nui_popup = require("nui.popup")(_popup_options)
end

---@type SandrPopup
local replace_popup = { mounted = false }

---@param source_win_id number
local function init_replace_popup(source_win_id)
    local _popup_options =
        popup_options.get_replace_popup_options(source_win_id)
    replace_popup.nui_popup = require("nui.popup")(_popup_options)
end

------------------------------------------------------------------------------------------
-----------------------------------GENERAL------------------------------------------------
------------------------------------------------------------------------------------------

---@param popup SandrPopup
local function show_popup(popup)
    if visible then
        return
    end
    if not popup.mounted then
        popup.nui_popup:mount()
        popup.mounted = true
        return
    end

    popup.nui_popup:show()
end

---@param popup SandrPopup
local function hide_popup(popup)
    if not popup.mounted or not visible then
        return
    end
    popup.nui_popup:hide()
end

---@param cmdline_text string
---@return string: search_term
---@return string: replace_term
---@return string: flags
local function parse_cmdline_text(cmdline_text)
    -- First pattern tries to match format with replace term: s/search/replace/flags
    local search_term, replace_term, flags =
        cmdline_text:match("s/([^/]+)/([^/]+)/([^/]*)")

    -- If replace term is not found, try to match format without replace term: s/search//flags
    if not search_term then
        search_term, flags = cmdline_text:match("s/([^/]+)/()/([^/]*)")
        replace_term = "" -- Set replace term to empty string
    end

    return search_term or "", replace_term or "", flags or ""
end

--HACK to fix issue with text now being drawn
---@param popup SandrPopup
---@param hlgroup? string
local function redraw(popup, hlgroup)
    if not namespace then
        return
    end
    vim.api.nvim_buf_clear_namespace(popup.nui_popup.bufnr, namespace, 0, -1)
    vim.api.nvim_buf_add_highlight(
        popup.nui_popup.bufnr,
        namespace,
        hlgroup or "NormalFloat",
        0,
        1,
        -1
    )
end
---@param popup SandrPopup
---@param text string
local function set_text_on_popup(popup, text)
    if not text or text == "" or popup.value == text then
        redraw(popup, "Cursor") -- FIXME Why does this not work??
        return
    end
    popup.value = text
    vim.api.nvim_buf_set_lines(popup.nui_popup.bufnr, 0, -1, false, { text })
    redraw(popup)
end

---@param text string
---@param cursor_pos number
local function get_cursor_positions(text, cursor_pos)
    local search_term_cursor_pos = -1
    local replace_term_cursor_pos = -1
    local search_term, replace_term, _ = parse_cmdline_text(text)
    if search_term and search_term ~= "" then
        local search_term_start, search_term_end = text:find(search_term)
        if
            cursor_pos >= search_term_start
            and cursor_pos <= search_term_end
        then
            search_term_cursor_pos = cursor_pos - search_term_start
        end
    end
    if replace_term and replace_term ~= "" then
        local replace_term_start, replace_term_end = text:find(replace_term)
        if
            cursor_pos >= replace_term_start
            and cursor_pos <= replace_term_end
        then
            replace_term_cursor_pos = cursor_pos - replace_term_start
        end
    end
    return search_term_cursor_pos, replace_term_cursor_pos
end

---@param buffer number
---@param cursor_pos number
local function draw_cursor(buffer, cursor_pos)
    if not namespace then
        return
    end
    vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
    if cursor_pos == -1 then
        return
    end
    vim.api.nvim_buf_add_highlight(
        buffer,
        namespace,
        "Cursor",
        0,
        cursor_pos,
        cursor_pos + 1
    )
end

------------------------------------------------------------------------------------------
-----------------------------------EXPORTS------------------------------------------------
------------------------------------------------------------------------------------------
local M = {}

M.hide_replace_popup = function()
    hide_popup(search_popup)
    hide_popup(replace_popup)
    visible = false
end

---@param source_win_id number
---@param _namespace number
M.show_replace_popup = function(source_win_id, _namespace)
    if not _namespace then
        return
    end
    namespace = _namespace
    if not search_popup.nui_popup then
        init_search_popup(source_win_id)
    end

    if not replace_popup.nui_popup then
        init_replace_popup(source_win_id)
    end
    show_popup(search_popup)
    show_popup(replace_popup)
    visible = true
end

local current_text = nil
local current_cursor_pos = nil
M.get_current_text = function()
    return current_text
end
M.get_current_cursor_pos = function()
    return current_cursor_pos
end

--- @param text string
--- @param cursor_pos number
--- @param prefix string
M.update = function(text, cursor_pos, prefix)
    current_text = text
    current_cursor_pos = cursor_pos
    local search_term, replace_term, _ = parse_cmdline_text(text)

    set_text_on_popup(search_popup, search_term)
    set_text_on_popup(replace_popup, replace_term)
    local search_term_cursor_pos, replace_term_cursor_pos =
        get_cursor_positions(text, cursor_pos)
    draw_cursor(search_popup.nui_popup.bufnr, search_term_cursor_pos)
    draw_cursor(replace_popup.nui_popup.bufnr, replace_term_cursor_pos)
end

return M
