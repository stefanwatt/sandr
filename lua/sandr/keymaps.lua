local dialog_manager = require("sandr.dialog-manager")
local matches = require("sandr.matches")
local actions = require("sandr.actions")

local M = {}
local default_modes = { "n", "i", "x" }
local default_opts = { noremap = true, silent = true }

---@param search_input_bufnr number
---@param replace_input_bufnr number
local function setup_buffer_local_keymaps(
    search_input_bufnr,
    replace_input_bufnr
)
    local buffers = { search_input_bufnr, replace_input_bufnr }
    vim.keymap.set({ "n", "i", "x" }, "<CR>", function()
        --noop
    end, { noremap = true, silent = true, buffer = search_input_bufnr })
    for _, bufnr in ipairs(buffers) do
        vim.keymap.set(
            --TODO needs to be availble also when not in the buffre
            { "n", "i", "x" },
            Config.keymaps.toggle,
            dialog_manager.hide_dialog,
            { noremap = true, silent = true, buffer = bufnr }
        )
        vim.keymap.set(
            { "n", "i" },
            Config.keymaps.prev_match,
            actions.prev_search_result,
            { noremap = true, silent = true, buffer = bufnr }
        )
        vim.keymap.set(
            { "n", "i" },
            Config.keymaps.next_match,
            actions.next_search_result,
            { noremap = true, silent = true, buffer = bufnr }
        )
    end
end

local function update_search_input_layout()
    local search_term = dialog_manager.get_search_term()
    actions.search_input_change(search_term)
    dialog_manager.update_search_input_layout()
end

--TODO all should be buffer local tbh
---@return Sandr.Keymap[]
local function get_keymaps()
    return {
        {
            lhs = Config.keymaps.toggle_ignore_case,
            rhs = function()
                Config.ignore_case = not Config.ignore_case
                update_search_input_layout()
            end,
        },
        {

            lhs = Config.keymaps.toggle_preserve_case,
            rhs = function()
                Config.preserve_case = not Config.preserve_case
                update_search_input_layout()
            end,
        },
        {
            lhs = Config.keymaps.toggle_regex,
            rhs = function()
                Config.regex = not Config.regex
                update_search_input_layout()
            end,
        },

        {
            lhs = "<S-CR>",
            rhs = function()
                dialog_manager.replace_all()
                dialog_manager.hide_dialog()
                M.teardown()
            end,
        },
        {
            lhs = Config.keymaps.jump,
            rhs = dialog_manager.jump,
        },
    }
end

local original_keymaps = {}

local function save_original_keymap(modes, lhs)
    for _, mode in ipairs(modes) do
        local existing_keymap = vim.api.nvim_get_keymap(mode)
        for _, keymap in ipairs(existing_keymap) do
            if keymap.lhs == lhs then
                if not original_keymaps[mode] then
                    original_keymaps[mode] = {}
                end
                table.insert(original_keymaps[mode], keymap)
                break
            end
        end
    end
end

local function restore_original_keymaps()
    for mode, keymaps in pairs(original_keymaps) do
        for _, keymap in ipairs(keymaps) do
            vim.keymap.set(
                mode,
                keymap.lhs,
                keymap.rhs or keymap.callback,
                { noremap = keymap.noremap == 1, silent = keymap.silent == 1 }
            )
        end
    end
end

function M.teardown()
    local keymaps = get_keymaps()
    for _, keymap in pairs(keymaps) do
        vim.keymap.del(keymap.modes or default_modes, keymap.lhs)
    end
    restore_original_keymaps()
end

---@param search_input_bufnr number
---@param replace_input_bufnr number
function M.setup(search_input_bufnr, replace_input_bufnr)
    local keymaps = get_keymaps()
    for _, keymap in pairs(keymaps) do
        local modes = keymap.modes or default_modes
        save_original_keymap(modes, keymap.lhs)
        vim.keymap.set(
            modes,
            keymap.lhs,
            keymap.rhs,
            keymap.opts or default_opts
        )
    end
    dialog_manager.on("hide", { cb = M.teardown, name = "teardown" })
    dialog_manager.on(
        "search_input_change",
        { cb = actions.search_input_change, name = "search_input_change" }
    )
    dialog_manager.on(
        "replace_input_change",
        { cb = actions.replace_input_change, name = "replace_input_change" }
    )
    dialog_manager.on("replace_input_submit", {
        cb = function(search_term, replace_term)
            dialog_manager.hide_dialog()
            actions.replace_input_submit(search_term, replace_term)
        end,
        name = "replace_input_submit",
    })
    setup_buffer_local_keymaps(search_input_bufnr, replace_input_bufnr)
end

return M
