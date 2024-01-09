local dialog_manager = require("sandr.dialog-manager")
local utils = require("sandr.utils")

local mounted = false

local M = {}

local count = 1
M.on = function()
    ---@param event string
    return utils.debounce(function(event, ...)
        print("called " .. count .. " times")
        count = count + 1
        if event == "cmdline_show" then
            local status, text, cursor_pos, prefix =
                pcall(utils.parse_ext_cmdline_args, { ... })
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
                        vim.api.nvim_get_current_win()
                    )
                    mounted = true
                    return
                end
                dialog_manager.update(text, cursor_pos, prefix)
                vim.api.nvim_input(" <Left><Del>")
            end)
        elseif event == "cmdline_hide" then
            dialog_manager.hide_replace_popup()
            mounted = false
        end
    end, 1)
end

return M
