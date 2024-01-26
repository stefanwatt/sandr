local dialog_manager = require("sandr.dialog-manager")
local actions = require("sandr.actions")
local state = require("sandr.state")

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

local original_keymaps = {}

local function save_original_keymap(modes, lhs)
    for _, mode in ipairs(modes) do
        local existing_keymap = vim.api.nvim_get_keymap(mode)
        for _, keymap in ipairs(existing_keymap) do
            if keymap.lhs == lhs then
                if not original_keymaps[mode] then
                    original_keymaps[mode] = {}
                end
                table.insert(original_keymaps[mode], keymap)
                break
            end
        end
    end
end

local function restore_original_keymaps()
    for mode, keymaps in pairs(original_keymaps) do
        for _, keymap in ipairs(keymaps) do
            vim.keymap.set(
                mode,
                keymap.lhs,
                keymap.rhs or keymap.callback,
                { noremap = keymap.noremap == 1, silent = keymap.silent == 1 }
            )
        end
    end
end

function M.teardown()
    local keymaps = get_keymaps()
    for _, keymap in pairs(keymaps) do
        vim.keymap.del(keymap.modes or default_modes, keymap.lhs)
    end
    restore_original_keymaps()
end

function M.setup()
    local keymaps = get_keymaps()
    for _, keymap in pairs(keymaps) do
        local modes = keymap.modes or default_modes
        save_original_keymap(modes, keymap.lhs)
        vim.keymap.set(
            modes,
            keymap.lhs,
            keymap.rhs,
            keymap.opts or default_opts
        )
    end
    table.insert(dialog_manager.hooks.on_hide, M.teardown)
end

return M
