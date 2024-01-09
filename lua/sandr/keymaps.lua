local utils = require("sandr.utils")
local dialog_manager = require("sandr.dialog-manager")
local movement = require("sandr.movement")
local state = require("sandr.state")

local config = state.get_config()

for _, motion in pairs(movement.motions) do
    vim.keymap.set("c", motion, function()
        if dialog_manager.can_move(motion) then
            movement.move_cursor(motion)
        end
    end, { noremap = true })
end

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
        state.set_search_term_completion_index(new_search_term_completion_index)
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
end, { noremap = true })
vim.keymap.set("c", config.jump_backward, function()
    if utils.is_substitute_command() then
        movement.jump_to_search()
    end
end, { noremap = true })
