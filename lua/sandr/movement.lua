local utils = require("sandr.utils")
local dialog_manager = require("sandr.dialog-manager")

local function delete_left()
    local cmdline = utils.get_cmd_line()
    if not cmdline then
        return
    end
    local cursor_pos = vim.fn.getcmdpos()
    if not cursor_pos then
        return
    end
    local new_cmdline = cmdline:sub(1, cursor_pos - 2)
        .. cmdline:sub(cursor_pos, #cmdline)
    local new_cursor_pos = cursor_pos - 1
    return new_cmdline, new_cursor_pos
end

local M = {}
---@enum SandrMotion
M.motions = {
    left = "<Left>",
    right = "<Right>",
    up = "<Up>",
    down = "<Down>",
    bs = "<BS>",
}
---@param motion SandrMotion
M.move_cursor = function(motion)
    if motion == "<Left>" and vim.fn.getcmdpos() > 1 then
        vim.fn.setcmdline(vim.fn.getcmdline(), vim.fn.getcmdpos() - 1)
    end
    if motion == "<Right>" then
        vim.fn.setcmdline(vim.fn.getcmdline(), vim.fn.getcmdpos() + 1)
    end
    if motion == "<BS>" and vim.fn.getcmdpos() > 1 then
        local new_cmdline, new_cursor_pos = delete_left()
        if not new_cmdline or not new_cursor_pos then
            return
        end
        vim.fn.setcmdline(new_cmdline, new_cursor_pos)
        dialog_manager.update(new_cmdline:sub(2), new_cursor_pos, "foo")
    end
end

M.jump_to_replace = function()
    local cursor = utils.cursor_pos_in_subst_cmd()
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions()
    if
        not first_slash_pos
        or not second_slash_pos
        or not third_slash_pos
        or cursor ~= "search"
    then
        return
    end
    vim.fn.setcmdline(vim.fn.getcmdline(), third_slash_pos)
end

M.jump_to_search = function()
    local cursor = utils.cursor_pos_in_subst_cmd()
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions()
    if
        not first_slash_pos
        or not second_slash_pos
        or not third_slash_pos
        or cursor ~= "replace"
    then
        return
    end
    utils.set_cmd_line_pos(second_slash_pos)
end

return M
