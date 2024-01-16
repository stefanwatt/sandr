local dialog_manager = require("sandr.dialog-manager")
local utils = require("sandr.utils")
local state = require("sandr.state")
local ext_cmdline = require("sandr.ext-cmdline")
local ns = vim.api.nvim_create_namespace("sandr-popup")
local keymaps = require("sandr.keymaps")

local group = vim.api.nvim_create_augroup("lazyvim_sandr", { clear = true })

local count = 1
local attached = false
local attach, timer = utils.debounce(function()
    print("[" .. tostring(count) .. "] attach")
    count = count + 1
    if utils.is_substitute_command() and not attached then
        attached = true
        keymaps.setup()
        vim.ui_attach(ns, { ext_cmdline = true }, ext_cmdline.attach)
        dialog_manager.show_replace_popup(vim.api.nvim_get_current_win())
        return
    end
end, 1)

local function create_cmdline_changed_autocmd()
    vim.api.nvim_create_autocmd("CmdlineChanged", {
        group = group,
        pattern = "*",
        callback = attach,
        once = true,
    })
end
create_cmdline_changed_autocmd()

vim.api.nvim_create_autocmd("CmdlineLeave", {
    -- TODO investigate why this runs twice
    group = group,
    pattern = "*",
    callback = function()
        count = count + 1
        if not attached then
            return
        end
        state.set_search_term_completion_index(1)
        state.set_replace_term_completion_index(1)
        pcall(timer.close)
        attached = false
        keymaps.teardown()
        vim.ui_detach(ns)
        dialog_manager.hide_replace_popup()
        create_cmdline_changed_autocmd()
    end,
})
