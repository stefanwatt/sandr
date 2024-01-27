local dialog_manager = require("sandr.dialog-manager")
local actions = require("sandr.actions")
local state = require("sandr.state")

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
            { "n", "i", "x" },
            Config.toggle,
            dialog_manager.hide_dialog,
            { noremap = true, silent = true, buffer = bufnr }
        )
        vim.keymap.set(
            { "n", "i" },
            "<Up>",
            actions.prev_search_result,
            { noremap = true, silent = true, buffer = bufnr }
        )
        vim.keymap.set(
            { "n", "i" },
            "<Down>",
            actions.next_search_result,
            { noremap = true, silent = true, buffer = bufnr }
        )
    end
end
---@return SandrKeymap[]
local function get_keymaps()
    return {
        {
            lhs = Config.toggle_ignore_case,
            rhs = actions.toggle_ignore_case,
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
            lhs = Config.jump,
            rhs = function()
                print("jump")
                dialog_manager.jump()
            end,
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
    -- dialog_manager.on(
    --     "replace_input_change",
    --     { cb, name = "replace_input_change" }
    -- )
    -- dialog_manager.on(
    --     "search_input_submit",
    --     { cb, name = "search_input_submit" }
    -- )
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
