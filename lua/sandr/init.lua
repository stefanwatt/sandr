local keymaps = require("sandr.keymaps")
local dialog_manager = require("sandr.dialog-manager")

local utils = require("sandr.utils")
local state = require("sandr.state")

---@type SandrConfig
local default_config = {
    toggle = "<C-h>",
    toggle_ignore_case = "<C-i>",
    jump_forward = "<Tab>",
    jump_backward = "<S-Tab>",
    range = "%",
    flags = "gc",
}
local config = default_config

local M = {}
---@param user_config? SandrUserConfig
M.setup = function(user_config)
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
        or default_config
    state.read_from_db()
    state.set_config(config) -- needs to be called before setting keymaps
end
---@param args SandrArgs
M.search_and_replace = function(args)
    keymaps.setup()
    local selection = args.visual and utils.buf_vtext() or ""
    dialog_manager.show_dialog(vim.api.nvim_get_current_win(), selection)
end

return M
