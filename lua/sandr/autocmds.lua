local utils = require("sandr.utils")
local state = require("sandr.state")
local ext_cmdline = require("sandr.ext-cmdline")
local ns = vim.api.nvim_create_namespace("sandr-popup")
local keymaps = require("sandr.keymaps")

local group = vim.api.nvim_create_augroup("lazyvim_sandr", { clear = true })

local attached = false
local attach, timer = utils.debounce(function()
    if utils.is_substitute_command() and not attached then
        attached = true
        keymaps.setup()
        vim.ui_attach(ns, { ext_cmdline = true }, ext_cmdline.on())
    end
    if not utils.is_substitute_command() and attached then
        attached = false
        keymaps.teardown()
        vim.ui_detach(ns)
    end
end, 1)

vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = group,
    pattern = "*",
    callback = attach,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    pattern = "*",
    callback = function()
        state.set_search_term_completion_index(1)
        state.set_replace_term_completion_index(1)
        pcall(timer.close)
    end,
})
