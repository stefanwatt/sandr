local keymaps = require("sandr.keymaps")
local dialog_manager = require("sandr.dialog-manager")

local utils = require("sandr.utils")

---@type Sandr.Config
local default_config = {
    keymaps = {
        toggle = "<C-h>",
        toggle_ignore_case = "<A-i>",
        toggle_preserve_case = "<A-p>",
        toggle_regex = "<A-r>",
        jump = "<Tab>",
        next_match = "<C-n>",
        prev_match = "<C-p>",
    },
    ignore_case = false,
    regex = false,
    replacement_preview = true,
    preserve_case = false,
}
---@type Sandr.Config
Config = default_config
---@type number
SourceWinId = 0

local M = {}

---@param user_config? Sandr.ConfigUpdate
function M.setup(user_config)
    Config = vim.tbl_deep_extend("force", default_config, user_config or {})
        or default_config
end

---@param args Sandr.Args
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
