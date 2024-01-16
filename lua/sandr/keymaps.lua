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

    vim.keymap.set("c", config.completion, function()
        local cursor = utils.cursor_pos_in_subst_cmd()
        if cursor == "search" then
            local last_search_terms = state.get_last_search_terms()
            local search_term_completion_index =
                state.get_search_term_completion_index()
            local item = last_search_terms[search_term_completion_index]
            local new_search_term_completion_index = search_term_completion_index
                        < #last_search_terms
                    and search_term_completion_index + 1
                or 1
            state.set_search_term_completion_index(
                new_search_term_completion_index
            )
            utils.insert_search_term(item)
        elseif cursor == "replace" then
            local last_replace_terms = state.get_last_replace_terms()
            local replace_term_completion_index =
                state.get_replace_term_completion_index()
            local item = last_replace_terms[replace_term_completion_index]
            local new_replace_term_completion_index = replace_term_completion_index
                        < #last_replace_terms
                    and replace_term_completion_index + 1
                or 1
            state.set_replace_term_completion_index(
                new_replace_term_completion_index
            )
            utils.insert_replace_term(item)
        end
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
    vim.keymap.del("c", "<CR>")
    vim.keymap.del("c", config.completion)
    vim.keymap.del("c", config.jump_forward)
    vim.keymap.del("c", config.jump_backward)
end

return M
