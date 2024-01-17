local utils = require("sandr.utils")
local dialog_manager = require("sandr.dialog-manager")
local movement = require("sandr.movement")
local state = require("sandr.state")

local M = {}

M.setup = function()
    local config = state.get_config()

    for _, motion in pairs(movement.motions) do
        vim.keymap.set("c", motion, function()
            if dialog_manager.can_move(motion) then
                movement.move_cursor(motion)
            end
        end, { noremap = true })
    end

    vim.keymap.set("c", "<A-i>", function()
        local current_config = state.get_config()
        if current_config.flags == "gci" then
            state.update_config({ flags = "gc" })
        else
            state.update_config({ flags = "gci" })
        end
        utils.set_cmd_line(
            dialog_manager.get_search_term(),
            dialog_manager.get_replace_term(),
            false,
            state.get_config()
        )
    end, {})
    vim.keymap.set("c", "/", function() end, {})
    vim.keymap.set("c", config.toggle, function()
        vim.api.nvim_input("<Esc>")
    end, {})

    vim.keymap.set("c", "<CR>", function()
        utils.substitute_loop_around(
            dialog_manager.get_search_term(),
            dialog_manager.get_replace_term()
        )
        vim.schedule(function()
            vim.api.nvim_input("<Esc>")
            dialog_manager.hide_replace_popup()
        end)
    end, {})

    vim.keymap.set("c", "<S-CR>", function()
        local pattern = dialog_manager.get_search_term()
        local replacement = dialog_manager.get_replace_term()
        utils.substitute_all(pattern, replacement)
        vim.schedule(function()
            vim.api.nvim_input("<Esc>")
            dialog_manager.hide_replace_popup()
        end)
    end, {})

    vim.keymap.set("c", config.jump_forward, function()
        if utils.is_substitute_command() then
            movement.jump_to_replace()
        end
    end, {})

    vim.keymap.set("c", config.jump_backward, function()
        if utils.is_substitute_command() then
            movement.jump_to_search()
        end
    end, {})
end

M.teardown = function()
    local config = state.get_config()
    for _, motion in pairs(movement.motions) do
        vim.keymap.del("c", motion)
    end
    vim.keymap.del("c", config.toggle)
    vim.keymap.del("c", "<C-i>")
    vim.keymap.del("c", "<CR>")
    vim.keymap.del("c", "/")
    vim.keymap.del("c", config.jump_forward)
    vim.keymap.del("c", config.jump_backward)
end

return M
