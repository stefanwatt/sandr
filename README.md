<div align="center">

# Sandr

##### Hacking the builtin search and replace for better ergonomics

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

## ⇁ WIP

If you experience any issues, see some improvement you think would be amazing, or just have some
feedback for sandr (or me), make an issue!

## The builtin search and replace is not very ergonomic:

1. You have to type boilerplate every time
2. You cannot easily jump between search and replace terms
3. You cannot get back to your previous search and replace terms easily
4. You cannot easily use the highlighted text as input for the search and replace terms

## The Solutions:

1. Apply simple keymap to abstract away the boilerplate and place cursor in the correct spot
2. Press tab to jump to the next position (search -> replace -> flags) or shift-tab to go backwards.
3. Jumping forward will also autofill the previous search and replace terms and
   you can use a different keymap(<C-Space>) to get back even older search and replace terms.
4. Triggering search and replace with a visual selection will automatically use the selected text
   as the search term and place the cursor in the replace field.

## The Approach:

The builtin search-and-replace-functionality is obviously very powerful and works great as is,
but I wanted to get the niceties of the search and replace feature in VSCode or Intellij in there as well.
This is a decent middleground for me. Already works better than anything else I've used.

## The Challenges:

In VSCode and Intellij when you open the search and replace the previous search/replace term is prefilled
and you can decide if you wanna just use that and press enter or just type over it.
To me that's a very nice behaviour and allows for a very fast workflow.
Obviously there's no highlighting text and typing "over" it as there is in a non-modal editor.
And there's additional limitations in the command line (no visual/normal mode there).
So the best solution I could come up with was to still just let the user get to typing quickly by not prefilling anything,
but doing the autofill when jumping forward. Seemed like a decent compromise.

## Installation

-   install using your favorite plugin manager (`lazy` in this example)

```lua
{
		"stefanwatt/sandr",
		opts = {
			jump_forward = "<Tab>",
			jump_backward = "<S-Tab>",
			completion = "<C-Space>",
            range = "" -- see :h Range
            flags = "gc" --see :h :s_flags
		},
		keys = {
			{
				"<C-h>",
				mode = { "n" },
				function()
					require("sandr").search_and_replace({})
				end,
				desc = "Search and replace",
			},
			{
				"<C-h>",
				mode = { "v" },
				function()
					require("sandr").search_and_replace({ visual = true })
				end,
				desc = "Search and replace visual",
			},
		},
	}

```
