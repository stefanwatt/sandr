local dialog_manager = require("sandr.dialog-manager")
local actions = require("sandr.actions")
local state = require("sandr.state")

local M = {}
---@class SandrKeymap
---@field lhs string
---@field rhs function
---@field modes? string[]|string
---@field opts? any

local default_modes = { "n", "i", "x" }
local default_opts = { noremap = true, silent = true }

---@param config SandrConfig
---@return SandrKeymap[]
local function get_keymaps(config)
    return {
        {
            lhs = config.toggle_ignore_case,
            rhs = actions.toggle_ignore_case,
        },
        {
            lhs = "<S-CR>",
            rhs = function()
                dialog_manager.replace_all()
                dialog_manager.hide_dialog()
                M.teardown()
            end,
        },
        {
            lhs = config.jump_forward,
            rhs = function()
                dialog_manager.jump()
            end,
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
