local state = require("sandr.state")
local actions = require("sandr.actions")
local input_options = require("sandr.input-options")

local M = {}
local visible = false

---@class SandrInput
---@field value? string
---@field mounted boolean
---@field nui_input? NuiInput
---@field source_win_id? number
---@field prompt string
---@field focused boolean

---@type SandrInput
local search_input = {
    mounted = false,
    prompt = "Search: ",
    focused = true,
}

---@param source_win_id number
local function init_search_input(source_win_id)
    ---@param value string
    local function on_submit(value)
        --TODO
    end

    ---@param value string
    local function on_change(value)
        search_input.value = value
    end

    local popup_opts, input_opts = input_options.get_search_input_options(
        source_win_id,
        on_submit,
        on_change
    )
    search_input.nui_input = require("nui.input")(popup_opts, input_opts)
    search_input.source_win_id = source_win_id
end

---@type SandrInput
local replace_input = {
    mounted = false,
    prompt = "Replace: ",
    focused = false,
}

---@param source_win_id number
local function init_replace_input(source_win_id)
    ---@param value string
    local function on_submit(value)
        vim.api.nvim_set_current_win(source_win_id)
        actions.confirm(search_input.value, value)
        M.hide_dialog()
    end

    ---@param value string
    local function on_change(value)
        replace_input.value = value
    end
    local popup_opts, input_opts = input_options.get_replace_input_options(
        source_win_id,
        on_submit,
        on_change
    )
    replace_input.nui_input = require("nui.input")(popup_opts, input_opts)
    replace_input.source_win_id = source_win_id
end

local focus_search_input = function()
    vim.api.nvim_set_current_win(search_input.nui_input.winid)
    search_input.focused = true
    replace_input.focused = false
end

local focus_replace_input = function()
    vim.api.nvim_set_current_win(replace_input.nui_input.winid)
    search_input.focused = false
    replace_input.focused = true
end
------------------------------------------------------------------------------------------
-----------------------------------GENERAL------------------------------------------------
------------------------------------------------------------------------------------------
---@param input SandrInput
local function hide_input(input)
    if not input.mounted or not visible then
        return
    end
    input.nui_input:hide()
end

local function hide_dialog()
    hide_input(search_input)
    hide_input(replace_input)
    visible = false
end

---@param input SandrInput
local function set_exit_keymap(input)
    local lhs = state.get_config().toggle
    vim.keymap.set(
        { "n", "i", "x" },
        lhs,
        hide_dialog,
        { noremap = true, silent = true, buffer = input.nui_input.bufnr }
    )
end

---@param input SandrInput
local function show_input(input)
    if visible then
        return
    end
    if not input.mounted then
        input.nui_input:mount()
        set_exit_keymap(input)
        input.mounted = true
        return
    end

    input.nui_input:show()
end

------------------------------------------------------------------------------------------
-----------------------------------EXPORTS------------------------------------------------
------------------------------------------------------------------------------------------

M.jump = function()
    if search_input.focused then
        focus_replace_input()
    else
        focus_search_input()
    end
end
M.hide_dialog = hide_dialog

---@param source_win_id number
---@param search_term string
M.show_dialog = function(source_win_id, search_term)
    --TODO set search term

    if not replace_input.nui_input then
        init_replace_input(source_win_id)
    end
    if not search_input.nui_input then
        init_search_input(source_win_id)
    end
    show_input(replace_input)
    show_input(search_input)
    visible = true
end

---@return string search_term
M.get_search_term = function()
    return search_input.value
end

---@return string replace_term
M.get_replace_term = function()
    return replace_input.value
end

M.replace_all = function()
    vim.api.nvim_set_current_win(search_input.source_win_id)
    actions.replace_all(search_input.value, replace_input.value)
end

return M
