local utils = require("sandr.utils")
local state = require("sandr.state")

local M = {}
---@class SandrArgs
---@field visual boolean

---@class SandrConfig
---@field toggle string
---@field jump_forward string
---@field jump_backward string
---@field completion string
---@field range string
---@field flags string
local default_config = {
    toggle = "<C-h>",
    jump_forward = "<Tab>",
    jump_backward = "<S-Tab>",
    completion = "<C-Space>",
    range = "",
    flags = "gc",
}
local config = default_config
---@param user_config? SandrConfig
M.setup = function(user_config)
    config = vim.tbl_deep_extend("force", default_config, user_config or {})
        or default_config
    state.read_from_db()
    state.set_config(config) -- needs to be called before setting keymaps
    require("sandr.autocmds")
    require("sandr.keymaps")
    require("sandr.ext-cmdline")
end
M.setup()
---@param args SandrArgs
M.search_and_replace = function(args)
    local selection = args.visual and utils.buf_vtext() or ""
    local cmdline = config.range .. "s/" .. selection .. "//" .. config.flags
    local cmd = ":"
    if args.visual then
        cmd = "<Esc>" .. cmd
    end
    vim.api.nvim_input(cmd)
    local _, second_slash_pos, third_slash_pos =
        utils.get_slash_positions(cmdline)
    local cursor_pos = (args.visual and third_slash_pos or second_slash_pos)
    vim.schedule(function()
        vim.fn.setcmdline(cmdline, cursor_pos)
    end)
end

return M
