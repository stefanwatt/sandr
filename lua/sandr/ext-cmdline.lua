local dialog_manager = require("sandr.dialog-manager")
local utils = require("sandr.utils")
local state = require("sandr.state")

local M = {}
---@param prefix string
---@param text string
---@param cursor_pos number
local function render_dialog(prefix, text, cursor_pos)
    if
        not prefix == ":"
        or not utils.is_substitute_command()
        or (
            dialog_manager.get_current_text() == text
            and dialog_manager.get_current_cursor_pos() == cursor_pos
        )
    then
        return
    end
    dialog_manager.update(text, cursor_pos, prefix)
    local config = state.get_config()
    local default_cmdline = config.range .. "s///" .. config.flags
    -- HACK should be prevented somehow else
    if text and text ~= "" and text ~= default_cmdline then
        vim.api.nvim_input(" <Left><Del>")
    end
end
local attach, _ =
    ---@param event string
    utils.debounce(function(event, ...)
        if event ~= "cmdline_show" then
            return
        end
        local status, text, cursor_pos, prefix =
            pcall(utils.parse_ext_cmdline_args, { ... })
        if not status then
            return
        end
        vim.schedule(function()
            render_dialog(prefix, text, cursor_pos)
        end)
    end, 10)
M.attach = attach
return M
