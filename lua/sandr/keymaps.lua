local dialog_manager = require("sandr.dialog-manager")
local actions = require("sandr.actions")
local state = require("sandr.state")

--TODO teardown seems to not work properly
local M = {}
local default_modes = { "n", "i", "x" }
local default_opts = { noremap = true, silent = true }

---@return SandrKeymap[]
local function get_keymaps()
    return {
        {
            lhs = Config.toggle_ignore_case,
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
            lhs = Config.jump_forward,
            rhs = function()
                dialog_manager.jump()
            end,
        },
    }
end

function M.setup()
    local keymaps = get_keymaps()
    for _, keymap in pairs(keymaps) do
        vim.keymap.set(
            keymap.modes or default_modes,
            keymap.lhs,
            keymap.rhs,
            keymap.opts or default_opts
        )
    end
end

function M.teardown()
    local keymaps = get_keymaps()
    for _, keymap in pairs(keymaps) do
        vim.keymap.del(keymap.modes or default_modes, keymap.lhs)
    end
end

return M
