local Input = require("nui.input")
local highlight = require("sandr.highlight")
local utils = require("sandr.utils")
local matches = require("sandr.matches")
local actions = require("sandr.actions")
local input_options = require("sandr.input-options")

local M = {}
local visible = false
SearchInputBufnr = 0
ReplaceInputBufnr = 0

---@alias SandrEvent "hide"|"search_input_change"|"search_input_submit"|"replace_input_change"|"replace_input_submit"
---TODO make available through config
---@class SandrHookCB
---@field name string
---@field cb fun(...)
---
---@type table<SandrEvent, SandrHookCB[]>
local default_hooks = {
    hide = {},
    search_input_change = {},
    search_input_submit = {},
    replace_input_change = {},
    replace_input_submit = {},
}

local hooks = default_hooks

---@type Sandr.Input
local search_input = {
    mounted = false,
    prompt = "Search: ",
    focused = true,
}

local count = 1
local function get_search_input_options()
    ---@param value string
    local function on_submit(value)
        --TODO
    end

    ---@param value string
    local function on_change(value)
        print(
            "dialog-manager.search_input_changed #"
                .. tostring(count)
                .. " ; value="
                .. value
        )
        count = count + 1
        search_input.value = value
        for _, sandr_hook_cb in ipairs(hooks.search_input_change) do
            print("running hook")
            sandr_hook_cb.cb(value)
        end
    end

    local popup_opts, input_opts =
        input_options.get_search_input_options(on_submit, on_change)
    return popup_opts, input_opts
end

local function init_search_input()
    local popup_opts, input_opts = get_search_input_options()
    search_input.nui_input = Input(popup_opts, input_opts)
end

---@type Sandr.Input
local replace_input = {
    mounted = false,
    prompt = "Replace: ",
    focused = false,
}

local function get_replace_input_options()
    ---@param value string
    local function on_submit(value)
        for _, sandr_hook_cb in ipairs(hooks.replace_input_submit) do
            sandr_hook_cb.cb(search_input.value, value)
        end
    end

    ---@param value string
    local function on_change(value)
        replace_input.value = value
        for _, sandr_hook_cb in ipairs(hooks.replace_input_change) do
            sandr_hook_cb.cb(search_input.value, value)
        end
    end
    local popup_opts, input_opts =
        input_options.get_replace_input_options(on_submit, on_change)
    return popup_opts, input_opts
end

local function init_replace_input()
    local popup_opts, input_opts = get_replace_input_options()
    replace_input.nui_input = Input(popup_opts, input_opts)
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
---@param input Sandr.Input
local function hide_input(input)
    if not input.mounted or not visible then
        return
    end
    input.value = ""
    local bufnr = input.nui_input.bufnr
    if bufnr then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    end
    input.nui_input:hide()
end

local function hide_dialog()
    hide_input(search_input)
    hide_input(replace_input)
    for _, sandr_hook_cb in ipairs(hooks.hide) do
        sandr_hook_cb.cb()
    end
    M.hooks = default_hooks
    local bufnr = vim.api.nvim_win_get_buf(SourceWinId)
    highlight.clear_highlights(bufnr)
    visible = false
    vim.api.nvim_set_current_win(SourceWinId)
end

local function show_search_input()
    if visible then
        return
    end
    if not search_input.mounted then
        search_input.nui_input:mount()
        SearchInputBufnr = search_input.nui_input.bufnr
        search_input.mounted = true
        return
    end
    search_input.nui_input:show()
    M.update_search_input_layout()
    vim.api.nvim_command("startinsert")
end

local function show_replace_input()
    if visible then
        return
    end
    if not replace_input.mounted then
        replace_input.nui_input:mount()
        ReplaceInputBufnr = replace_input.nui_input.bufnr
        replace_input.mounted = true
        return
    end
    local popup_opts, input_opts = get_replace_input_options()
    replace_input.nui_input.update_layout(replace_input.nui_input, popup_opts)
    replace_input.nui_input:show()
    vim.api.nvim_command("startinsert")
end

------------------------------------------------------------------------------------------
-----------------------------------EXPORTS------------------------------------------------
------------------------------------------------------------------------------------------

function M.jump()
    if search_input.focused then
        print("focus_replace_input")
        focus_replace_input()
    else
        print("focus_search_input")
        focus_search_input()
    end
end

---@param event SandrEvent
---@param hook_cb SandrHookCB
function M.on(event, hook_cb)
    local existing_cb = utils.find(hooks[event], function(sandr_hook_cb)
        return sandr_hook_cb.name == hook_cb.name
    end)
    if not existing_cb then
        table.insert(hooks[event], hook_cb)
    end
end

M.hide_dialog = hide_dialog

---@param search_term string
---@return number search_input_bufnr
---@return number replace_input_bufnr
function M.show_dialog(search_term)
    --TODO apply highlighting when search_term is provided
    --TODO set search term
    vim.api.nvim_command("nohlsearch")
    if not replace_input.nui_input then
        init_replace_input()
    end
    if not search_input.nui_input then
        init_search_input()
    end
    show_replace_input()
    show_search_input()
    search_input.focused = true
    visible = true
    -- HACK sometimes a some buffer from the workspace is opened in the nui input
    vim.schedule(function()
        vim.api.nvim_win_set_buf(
            search_input.nui_input.winid,
            search_input.nui_input.bufnr
        )
        vim.api.nvim_win_set_buf(
            replace_input.nui_input.winid,
            replace_input.nui_input.bufnr
        )
    end)
    return search_input.nui_input.bufnr, replace_input.nui_input.bufnr
end

function M.replace_all()
    vim.api.nvim_set_current_win(SourceWinId)
    actions.replace_all(search_input.value, replace_input.value)
end

function M.update_search_input_layout()
    local popup_opts, input_opts = get_search_input_options()
    search_input.nui_input.border:set_text(
        "top",
        popup_opts.border.text.top,
        "left"
    )
    search_input.nui_input.update_layout(search_input.nui_input, popup_opts)
end

function M.get_search_term()
    return search_input.value
end

return M
