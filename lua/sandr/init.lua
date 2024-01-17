local keymaps = require("sandr.keymaps")
local ns = vim.api.nvim_create_namespace("sandr-popup")
local ext_cmdline = require("sandr.ext-cmdline")
local dialog_manager = require("sandr.dialog-manager")

local utils = require("sandr.utils")
local state = require("sandr.state")

local group = vim.api.nvim_create_augroup("lazyvim_sandr", { clear = true })
local attached = false
vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    pattern = "*",
    callback = function()
        if not attached then
            return
        end
        state.set_search_term_completion_index(1)
        state.set_replace_term_completion_index(1)
        keymaps.teardown()
        vim.ui_detach(ns)
        dialog_manager.hide_replace_popup()
        attached = false
    end,
})

local M = {}
---@class SandrArgs
---@field visual boolean

---@class SandrConfigUpdate
---@field toggle? string
---@field jump_forward? string
---@field jump_backward? string
---@field range? string
---@field flags? string

---@class SandrUserConfig
---@field toggle string
---@field jump_forward string
---@field jump_backward string

---@class SandrConfig
---@field toggle string
---@field jump_forward string
---@field jump_backward string
---@field range string
---@field flags string
local default_config = {
    toggle = "<C-h>",
    jump_forward = "<Tab>",
    jump_backward = "<S-Tab>",
    range = "%",
    flags = "gc",
}
local config = default_config
---@param user_config? SandrUserConfig
M.setup = function(user_config)
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
        or default_config
    state.read_from_db()
    state.set_config(config) -- needs to be called before setting keymaps
end
---@param args SandrArgs
M.search_and_replace = function(args)
    attached = true
    keymaps.setup()
    vim.ui_attach(ns, { ext_cmdline = true }, ext_cmdline.attach)
    dialog_manager.show_replace_popup(vim.api.nvim_get_current_win())
    local selection = args.visual and utils.buf_vtext() or ""
    utils.set_cmd_line(selection, "", args.visual, state.get_config())
end

return M
