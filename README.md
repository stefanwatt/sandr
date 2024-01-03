<div align="center">

# Sandr

##### Hacking the builtin search and replace for better ergonomics

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>
<!--toc:start-->

-   [Disclaimer](#wip)
-   [Search and replace in neovim](#search-and-replace-in-neovim)
-   [What I don't like/what I'm missing](#what-i-dont-likewhat-im-missing)
-   [How I tried to solve these things](#how-i-tried-to-solve-these-things)
-   [Installation](#installation)
-   [Example Usage:](#example-usage)
-   [The Challenges:](#the-challenges)

<!--toc:end-->

## WIP

If you experience any issues, see some improvement you think would be amazing, or just have some
feedback for sandr (or me), make an issue!

## Search and replace in neovim

seems to be something that keeps coming up as a pain point every now and then. I do like the builtin substitute command (something like :s/foo/bar/gc ), but there's some things that just work better for me ootb with the implementation in VSCode or IntelliJ.

## What I don't like/what I'm missing

<ol>
    <li id="problem_boilerplate">I don't want to type the "boilerplate" every time. It's nice that there's lot's of different options, but 95% of the time I just do a quick plain text replace.</li>
    <li id="problem_visual">I want to be able to prefill the search term with my visual selection</li>
    <li id="problem_remember">When toggling the search and replace dialog, I want the previous search/replace terms to be remembered and set as the default, but...
</li>
    <li id="problem_typing">... I also want to be able to start typing right away if I want to search/replace something different
</li>
    <li id="problem_jump">I want to be able to jump between search and replace term easily with a keymap</li>
</ol>

## How I tried to solve these things

To solve <a href="#problem_boilerplate">1</a> I can just create a simple keymap that abstracts away the "boilerplate" and puts the cursor at the correct spot. Even if I'm not saving keystrokes it's less mental overhead for me.

<a href="#problem_visual">2</a> is pretty trivial to solve with another keymap that first reads the visual selection, but nonetheless very useful for me to have.
Maybe it's a little easier to understand with some example usages. Assuming `<C-h>` as main keymap, `<Tab>` to jump forward, `<S-Tab>` to jump backward and `<C-Space>` to cycle through list of last terms would be.

<a href="#problem_remember">3</a>, <a href="#problem_typing">4</a>, and <a href="#problem_jump">5</a> were a little more challenging since you can't just highlight text and "type over it" in neovim as you could in a non-modal editor. So the solution I came up with was to not prefill anything, but still remember the last search/replace term(s). Then add a keymap in command line mode to jump to the next position (search->replace->flags). This keymap will also trigger autofill of the last search term. Additionally I provide the option for a third keymap to cycle through the last 10 search/replace terms. This is also stored in a json file and therefore persisted through sessions.

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

## Example Usage:

Maybe it's a little easier to understand with some examples. Assuming `<C-h>` as main keymap, `<Tab>` to jump forward, `<S-Tab>` to jump backward and `<C-Space>` to cycle through list of last terms would be.
Example Usage

-   `<C-h>foo<Tab>bar<CR>` Most simple case. Just prefilling the boilerplate. Could also use `<Right>` instead of `<Tab>`. Note that if there's a search term value present then it will not be replaced with the last search term when jumping.
-   `<C-h><Tab><Tab><CR>` This will just start search and replace with both the previous search and replace term. Here since the user hasn't typed anything as search term before `<Tab>` we will assume that it's desirable to auto fill with the last search term.
-   `<C-h><Tab>baz<CR>` Actually I want to replace the search term with something different
-   `viw<C-h>foo<CR>` Use word under cursor as search term and replace with `"foo"`
-   `<C-h>foo<Right>bar<S-Tab>baz<CR>` Actually I want to replace `"baz"` with `"bar"` not `"foo"` with `"bar"`. Jumping backwards will not replace the value with the last term. That just felt more natural to me.
-   `<C-h><C-Space><C-Space><C-Space><Tab>foo<CR>` I want to replace the third last search term with `"foo"`. Honestly not sure how useful this is, but why not.

## The Challenges:

What I really hated when implementing this is that apparently there's no api to interact with the command line in the same way you can with a buffer with `vim.api.nvim_buf_set_lines` or w/e. So I had to manually move the cursor around with `vim.api.nvim_feedkeys` and `<Left>`,`<Right>`,`<BS>`. It works, but it's ugly. Please let me know if there's an easier way to do this.
