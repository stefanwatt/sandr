local dialog_manager = require("sandr.dialog-manager")
local utils = require("sandr.utils")

local mounted = false

--- @param args table: The unstructured argument list.
--- @return string: text
--- @return number: cursor_pos
--- @return string: prefix
local function parse_ext_cmdline_args(args)
    local text = args[1][1][2]
    local cursor_pos = args[2]
    local prefix = args[3]
    return text, cursor_pos, prefix
end

local M = {}

M.on = function(ns)
    ---@param event string
    return function(event, ...)
        if event == "cmdline_show" then
            local status, text, cursor_pos, prefix =
                pcall(parse_ext_cmdline_args, { ... })
            if not status then
                return
            end
            vim.schedule(function()
                if
                    not prefix == ":"
                    or not utils.is_substitute_command()
                    or (
                        dialog_manager.get_current_text() == text
                        and dialog_manager.get_current_cursor_pos()
                            == cursor_pos
                    )
                then
                    return
                end
                if not mounted then
                    dialog_manager.show_replace_popup(
                        vim.api.nvim_get_current_win(),
                        ns
                    )
                    mounted = true
                    return
                end
                dialog_manager.update(text, cursor_pos, prefix)
                vim.api.nvim_input(" <bs>")
            end)
        elseif event == "cmdline_hide" then
            dialog_manager.hide_replace_popup()
            mounted = false
        end
    end
end

return M
