local utils = require("sandr.utils")
local movement = require("sandr.movement")
local state = require("sandr.state")

local M = {}

local function move_to_next_pos()
    local cursor = utils.cursor_pos_in_subst_cmd()
    if cursor == "search" then
        movement.from_search_to_replace()
    elseif cursor == "replace" then
        movement.from_replace_to_flags()
    end
end

local function move_to_prev_pos()
    local cursor = utils.cursor_pos_in_subst_cmd()
    if cursor == "end" then
        movement.from_flags_to_replace()
    elseif cursor == "replace" then
        movement.from_replace_to_search()
    end
end

local search_term_completion_index = 1
local replace_term_completion_index = 1

---@class SandrConfig
---@field jump_forward string
---@field jump_backward string
---@field completion string
---@field flags string
local default_config = {
    jump_forward = "<Tab>",
    jump_backward = "<S-Tab>",
    completion = "<C-Space>",
    flags = "gc",
}
local config = default_config
---@param user_config? SandrConfig
M.setup = function(user_config)
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
        or default_config
    vim.api.nvim_create_augroup("CmdLineLeave", { clear = true })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = "CmdLineLeave",
        pattern = "*",
        callback = function()
            search_term_completion_index = 1
            replace_term_completion_index = 1
        end,
    })
    state.read_from_db()
    vim.keymap.set("c", config.completion, function()
        local cursor = utils.cursor_pos_in_subst_cmd()
        if cursor == "search" then
            local last_search_terms = state.get_last_search_terms()
            local item = last_search_terms[search_term_completion_index]
            search_term_completion_index = search_term_completion_index
                        < #last_search_terms
                    and search_term_completion_index + 1
                or 1
            utils.insert_search_term(item)
        elseif cursor == "replace" then
            local last_replace_terms = state.get_last_replace_terms()
            local item = last_replace_terms[replace_term_completion_index]
            replace_term_completion_index = replace_term_completion_index
                        < #last_replace_terms
                    and replace_term_completion_index + 1
                or 1
            utils.insert_replace_term(item)
        end
    end, {})

    vim.keymap.set("c", config.jump_forward, function()
        if utils.is_substitute_command() then
            move_to_next_pos()
        else
            vim.api.nvim_feedkeys(config.jump_forward, "i", true)
        end
    end, { noremap = true })
    vim.keymap.set("c", config.jump_backward, function()
        if utils.is_substitute_command() then
            move_to_prev_pos()
        else
            vim.api.nvim_feedkeys(config.jump_backward, "i", true)
        end
    end, { noremap = true })
end
M.setup()

---@param opts table{visual:boolean}
M.search_and_replace = function(opts)
    local selection = opts.visual and utils.buf_vtext() or ""
    local cmd = ":%s/"
        .. selection
        .. "//"
        .. config.flags
        .. string.rep("<Left>", #config.flags + 1)
    if selection == "" then
        cmd = cmd .. "<Left>"
    end
    if opts.visual then
        cmd = "<Esc>" .. cmd
    end
    cmd = vim.api.nvim_replace_termcodes(cmd, true, false, true)
    vim.api.nvim_feedkeys(cmd, "n", true)
end

return M
