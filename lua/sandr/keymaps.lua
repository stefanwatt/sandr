local utils = require("sandr.utils")
local dialog_manager = require("sandr.dialog-manager")
local movement = require("sandr.movement")
local state = require("sandr.state")

local M = {}
---@class SandrKeymap
---@field lhs string
---@field rhs function
---@field modes? string[]|string
---@field opts? any

local default_modes = { "n", "i", "x" }
local default_opts = { noremap = true, silent = true }

local function toggle()
    --TODO
end

local function toggle_ignore_case()
    local current_config = state.get_config()
    if current_config.flags == "gci" then
        state.update_config({ flags = "gc" })
    else
        state.update_config({ flags = "gci" })
    end
end
local function confirm()
    utils.substitute_loop_around(
        dialog_manager.get_search_term(),
        dialog_manager.get_replace_term()
    )
    vim.schedule(function()
        dialog_manager.hide_replace_popup()
    end)
end
local function confirm_all()
    local pattern = dialog_manager.get_search_term()
    local replacement = dialog_manager.get_replace_term()
    utils.substitute_all(pattern, replacement)
    vim.schedule(function()
        dialog_manager.hide_replace_popup()
    end)
end
local function jump_forward()
    if utils.is_substitute_command() then
        movement.jump_to_replace()
    end
end
local function jump_backward()
    if utils.is_substitute_command() then
        movement.jump_to_search()
    end
end

---@param config SandrConfig
---@return SandrKeymap[]
local function get_keymaps(config)
    return {
        {
            lhs = config.toggle_ignore_case,
            rhs = toggle_ignore_case,
        },
        {
            lhs = config.toggle,
            rhs = toggle,
        },
        {
            lhs = "<CR>",
            rhs = confirm,
        },
        {
            lhs = "<S-CR>",
            rhs = confirm_all,
        },
        {
            lhs = config.jump_forward,
            rhs = jump_forward,
        },
        {
            lhs = config.jump_backward,
            rhs = jump_backward,
        },
    }
end

M.setup = function()
    local config = state.get_config()
    local keymaps = get_keymaps(config)
    for _, keymap in pairs(keymaps) do
        vim.keymap.set(
            keymap.modes or default_modes,
            keymap.lhs,
            keymap.rhs,
            keymap.opts or default_opts
        )
    end
end

M.teardown = function()
    local config = state.get_config()
    local keymaps = get_keymaps(config)
    for _, keymap in pairs(keymaps) do
        vim.keymap.del(keymap.modes or default_modes, keymap.lhs)
    end
end

return M
