local utils = require("sandr.utils")
local movement = require("sandr.movement")
local state = require("sandr.state")

local config = state.get_config()

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
        movement.move_to_next_pos()
    else
        vim.api.nvim_feedkeys(config.jump_forward, "i", true)
    end
end, { noremap = true })
vim.keymap.set("c", config.jump_backward, function()
    if utils.is_substitute_command() then
        movement.move_to_prev_pos()
    else
        vim.api.nvim_feedkeys(config.jump_backward, "i", true)
    end
end, { noremap = true })
