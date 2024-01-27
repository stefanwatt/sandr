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
---@type SandrConfig
Config = default_config
---@type number
SourceWinId = 0

local M = {}

---@param user_config? SandrUserConfig
function M.setup(user_config)
    Config = vim.tbl_deep_extend("force", default_config, user_config or {})
        or default_config
    state.read_from_db()
end

---@param args SandrArgs
function M.search_and_replace(args)
    local selection = args.visual and utils.buf_vtext() or ""
    SourceWinId = vim.api.nvim_get_current_win()
    local search_bufnr, replace_bufnr = dialog_manager.show_dialog(selection)
    dialog_manager.on("hide", {
        cb = function()
            vim.schedule(function()
                vim.api.nvim_set_current_win(SourceWinId)
            end)
        end,
        name = "reset_cursor",
    })
    vim.schedule(function()
        keymaps.setup(search_bufnr, replace_bufnr)
    end)
end

return M
