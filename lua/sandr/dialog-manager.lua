local highlight = require("sandr.highlight")
local utils = require("sandr.utils")
local matches = require("sandr.matches")
local state = require("sandr.state")
local actions = require("sandr.actions")
local input_options = require("sandr.input-options")

local M = {}
local visible = false

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
        local bufnr = vim.api.nvim_win_get_buf(source_win_id)
        local new_matches = matches.get_matches(bufnr, value)

        local current_match =
            matches.get_closest_match_after_cursor(new_matches, source_win_id)
        if not current_match or not new_matches or #new_matches == 0 then
            highlight.clear_highlights(bufnr)
            return
        end
        state.set_matches(new_matches)
        state.set_current_match(current_match)
        highlight.highlight_matches(new_matches, current_match, bufnr)
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
        local current_match = state.get_current_match()
        actions.confirm(search_input.value, value, current_match)
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
    local bufnr = vim.api.nvim_win_get_buf(search_input.source_win_id)
    highlight.clear_highlights(bufnr)
    visible = false
end

---@param input SandrInput
local function set_buffer_keymaps(input)
    --TODO maybe this can go to keymaps.lua
    local lhs = Config.toggle
    vim.keymap.set(
        { "n", "i", "x" },
        lhs,
        hide_dialog,
        { noremap = true, silent = true, buffer = input.nui_input.bufnr }
    )
    vim.keymap.set({ "n", "i" }, "<Up>", function()
        local current_match = state.get_current_match()
        local current_matches = state.get_matches()
        local prev_match =
            matches.get_prev_match(current_match, current_matches)
        if not prev_match then
            return
        end
        state.set_current_match(prev_match)
        local bufnr = vim.api.nvim_win_get_buf(input.source_win_id)
        highlight.highlight_matches(current_matches, prev_match, bufnr)
        local prev_match_line = prev_match.start.row
        local current_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(search_input.source_win_id)
        if not utils.is_range_in_viewport(prev_match_line) then
            utils.center_line(prev_match_line)
        end
        vim.api.nvim_set_current_win(current_win)
    end, { noremap = true, silent = true, buffer = input.nui_input.bufnr })
    vim.keymap.set({ "n", "i" }, "<Down>", function()
        local current_match = state.get_current_match()
        local current_matches = state.get_matches()
        local next_match =
            matches.get_next_match(current_match, current_matches)
        if not next_match then
            return
        end
        state.set_current_match(next_match)
        local bufnr = vim.api.nvim_win_get_buf(input.source_win_id)
        highlight.highlight_matches(current_matches, next_match, bufnr)
        local next_match_line = next_match.start.row
        local current_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(search_input.source_win_id)
        if not utils.is_range_in_viewport(next_match_line) then
            utils.center_line(next_match_line)
        end
        vim.api.nvim_set_current_win(current_win)
    end, { noremap = true, silent = true, buffer = input.nui_input.bufnr })
end

---@param input SandrInput
local function show_input(input)
    if visible then
        return
    end
    if not input.mounted then
        input.nui_input:mount()
        set_buffer_keymaps(input)
        input.mounted = true
        return
    end

    input.nui_input:show()
end

------------------------------------------------------------------------------------------
-----------------------------------EXPORTS------------------------------------------------
------------------------------------------------------------------------------------------

function M.jump()
    if search_input.focused then
        focus_replace_input()
    else
        focus_search_input()
    end
end

M.hide_dialog = hide_dialog

---@param source_win_id number
---@param search_term string
function M.show_dialog(source_win_id, search_term)
    --TODO apply highlighting when search_term is provided
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
function M.get_search_term()
    return search_input.value
end

---@return string replace_term
function M.get_replace_term()
    return replace_input.value
end

function M.replace_all()
    vim.api.nvim_set_current_win(search_input.source_win_id)
    actions.replace_all(search_input.value, replace_input.value)
end

return M
