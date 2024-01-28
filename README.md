<div align="center">

# Sandr

##### An nui based frontend for the builtin substitute command

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>
<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Disclaimer](#alpha)
- [Search and replace in neovim](#search-and-replace-in-neovim)
- [Why?](#why)
- [How does this plugin work?](#how-does-this-plugin-work)
- [Demo](#demo)
- [Installation](#installation)

<!-- TOC end -->


<!-- TOC --><a name="alpha"></a>
## 🚨🚨🚨ALPHA🚨🚨🚨

Use at your own risk. Expect bugs.
At the moment I consider this project mostly a learning experience for me.

<!-- TOC --><a name="search-and-replace-in-neovim"></a>
## Search and replace in neovim...

...seems to be something that keeps coming up as a pain point every now and then. I do like the builtin substitute command, but there's some things that just work better for me ootb with the implementation in VSCode or IntelliJ.
So why not keep using the builtin substitute, but build a frontend, that makes it more enjoyable to use. 

<!-- TOC --><a name="why"></a>
## Why?

<ol>
    <li>I just want something more convenient to cover 95% of my use cases.</li>
    <li id="problem_loop">
        The builtin substitute command offers no way to loop-around.
        If you want to replace in the entire buffer your only option is
        to use <code>%s/foo/bar/gc</code>, but this will always jump you to the beginning of the buffer, which is kinda jarring.
        If you instead start replacing from the current line, then obviously you will miss all the matches that are before your cursor.
    </li>
    <li id="problem_column">The builtin substitute command does not offer a way to specify the column to start from</li>
    <li id="problem_boilerplate">I don't want to type the "boilerplate" every time.</li>
    <li id="problem_visual">I want to be able to prefill the search term with my visual selection</li>
    <li id="problem_jump">I want to be able to jump between search and replace term easily with a keymap</li>
    <li id="problem_gui">I prefer a graphical dialog in the top right corner of my buffer where it's least likely to block text</li>
</ol>

<!-- TOC --><a name="how-does-this-plugin-work"></a>
## How does this plugin work?

Running

```lua
require("sandr").search_and_replace({})
```

will bring up an nui based dialog in the top right corner of the screen, that should look similar to what you might be used to from IDEs.
Start typing to highlight matches of the search term. Use `<Tab>` to jump to the replace term input.
Start typing your replace term and hit `<CR>` to start replacing. From now on you're just in the builtin substitute command with the confirm flag set.
So the keymaps that are shown on the bottom of the screen apply. However there's actually three substitute commands running in sequence.

1. Using regex, only replace on the current line starting after the cursor column.
2. Replace from the next line until the end of the buffer.
3. Replace from the beginning of the buffer until the current line.

So as expected you will start replacing from after your current cursor location and loop back around to where you started.
If you don't want to confirm every match you can just use `<S-CR>` while in the replace input to repace all matches in the buffer.
You can visually select text and then hit `<C-h>` to prefill the search term with the visual selection

Toggle
- Ignore Case with `<Alt-i>`
- Preserve Case with `<Alt-p>`
- Regex Mode with `<Alt-r>`

Jump to the next/previous match with `<C-n>` / `<C-p>`.

All these keymaps are just the default and can be configured of course.

<!-- TOC --><a name="demo"></a>
## Demo
### Loop Around
<img style="width:100%;" src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExeGI3bXh5ZGZ4NGo4NGpvd2Rwcnl1bmdyaWEzaG1wamE2ZWd1cGVwaiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/4mhFyAKzQe2HjGFrqW/giphy.gif">

### Ignore Case + Preserve Case
<img style="width:100%;" src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExa3JpcXhydHppY3l1enQ3cW82dzgzcWY0eWRwcGlpdjFpbjViNHgxcyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/RFgqwmXNrcfp0WB7XF/giphy.gif">

### Regex
<img style="width:100%;" src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExazRjMDEyZjJ4YXp0bmZhMGwwcXlwYjhoODJnc3NrMmd1M2w2NjdpYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/bIAaXBWyH5iHD5Udm9/giphy.gif">

<!-- TOC --><a name="installation"></a>
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
