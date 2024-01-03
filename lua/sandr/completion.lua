local M = {}
local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event
local utils = require("config.search-and-replace.builtin.utils")

---@param items string[]
---@param callback function(item: string)
M.show_menu = function(items, callback)
	if not items or #items == 0 then
		return
	end
	local screen_height = vim.api.nvim_get_option("lines")
	local cursor_screen_pos = vim.api.nvim_win_get_cursor(0)[1] + vim.api.nvim_win_get_position(0)[1] - 1
	local in_lower_quarter = cursor_screen_pos > (screen_height * 0.75)

	local menu_items = utils.map(items, function(item)
		return Menu.item(item)
	end)

	local menu = Menu({
		relative = {
			type = "win",
			winid = require("noice").api.get_cmdline_position().win,
		},
		zindex = 300,
		position = {
			col = in_lower_quarter and -5 or 5,
			row = in_lower_quarter and -1 or 1,
		},
		size = {
			width = 20,
			height = #menu_items,
		},
		border = {
			style = "rounded",
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:TelescopeBorder",
		},
	}, {
		lines = menu_items,
		max_width = 20,
		keymap = {
			focus_next = { "<C-Tab>", "<Up>" },
			focus_prev = { "C-S-Tab", "<Down>" },
			close = { "<Esc>", "<C-c>" },
			submit = { "<CR>", "<Space>" },
		},
		on_submit = function(item)
			callback(item)
		end,
	})

	menu:mount()

	menu:on(event.BufLeave, function()
		menu:unmount()
	end)
end

return M
