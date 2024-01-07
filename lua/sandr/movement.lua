local utils = require("sandr.utils")
local state = require("sandr.state")

local function insert_last_search_term()
    local cmdline = utils.get_cmd_line()
    if not cmdline then
        return
    end
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions(cmdline)
    if not first_slash_pos or not second_slash_pos or not third_slash_pos then
        return
    end
    local search_term = cmdline:sub(first_slash_pos + 1, second_slash_pos - 1)
    local last_search_term = state.get_last_search_term()
    if search_term == "" and last_search_term and last_search_term ~= "" then
        utils.feedkeys(last_search_term)
    end
    if search_term ~= "" then
        state.set_last_search_term(search_term)
    end
end

local function insert_last_replace_term()
    local cmdline = utils.get_cmd_line()
    if not cmdline then
        return
    end
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions(cmdline)
    if not first_slash_pos or not second_slash_pos or not third_slash_pos then
        return
    end
    local replace_term = cmdline:sub(second_slash_pos + 1, third_slash_pos - 1)
    local last_replace_term = state.get_last_replace_term()
    if replace_term == "" and last_replace_term and last_replace_term ~= "" then
        utils.feedkeys(last_replace_term)
    end
    if replace_term ~= "" then
        state.set_last_replace_term(replace_term)
    end
end

---@param position "search" | "replace" | "flags"
---@return string?: cmd
local function get_move_cmd(position)
    local cmdline = utils.get_cmd_line()
    if not cmdline then
        return
    end
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions(cmdline)
    if not first_slash_pos or not second_slash_pos or not third_slash_pos then
        return
    end
    local cursor_pos = vim.fn.getcmdpos()
    local destination = second_slash_pos
    if position == "search" then
        destination = second_slash_pos
    end
    if position == "replace" then
        destination = third_slash_pos
    end
    if position == "flags" then
        destination = #cmdline + 1
    end

    local left_of_destination = cursor_pos <= destination
    local direction = left_of_destination and "<RIGHT>" or "<LEFT>"
    local presses_needed = left_of_destination and destination - cursor_pos
        or cursor_pos - destination
    local cmd = string.rep(direction, presses_needed)
    return cmd
end

---@param position "search" | "replace" | "flags"
local function move_cursor_to(position)
    local cmd = get_move_cmd(position)
    if not cmd then
        return
    end
    utils.feedkeys(cmd)
end

local function from_search_to_replace()
    insert_last_search_term()
    move_cursor_to("replace")
end

local function from_replace_to_flags()
    insert_last_replace_term()
    move_cursor_to("flags")
end

local function from_flags_to_replace()
    move_cursor_to("replace")
end

local function from_replace_to_search()
    move_cursor_to("search")
end

local M = {}

---@param motion "<Left>" |"<Right>" |"<Up>" |"<Down>"
M.move_cursor = function(motion)
    if motion == "<Left>" then
        vim.fn.setcmdline(vim.fn.getcmdline(), vim.fn.getcmdpos() - 1)
    end
    if motion == "<Right>" then
        vim.fn.setcmdline(vim.fn.getcmdline(), vim.fn.getcmdpos() + 1)
    end
end
M.move_to_next_pos = function()
    local cursor = utils.cursor_pos_in_subst_cmd()
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions()
    if not first_slash_pos or not second_slash_pos or not third_slash_pos then
        return
    end
    if cursor == "search" then
        -- from_search_to_replace()
        vim.fn.setcmdline(vim.fn.getcmdline(), third_slash_pos)
    elseif cursor == "replace" then
        from_replace_to_flags()
    end
end

M.move_to_prev_pos = function()
    local cursor = utils.cursor_pos_in_subst_cmd()
    local first_slash_pos, second_slash_pos, third_slash_pos =
        utils.get_slash_positions()
    if not first_slash_pos or not second_slash_pos or not third_slash_pos then
        return
    end

    if cursor == "end" then
        from_flags_to_replace()
    elseif cursor == "replace" then
        vim.fn.setcmdline(vim.fn.getcmdline(), second_slash_pos)
    end
end

return M
