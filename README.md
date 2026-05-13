# zeal.nvim

Query and open [Zeal](https://zealdocs.org/) docsets without leaving Neovim.

![Search](https://i.imgur.com/NMgdSOh.png)
![Term](https://i.imgur.com/y2STYrK.png)

# Requirements

- sqlite3
- curl
- lynx, w3m or any other terminal browser

## Optional Dependencies

- [snacks.nvim](https://github.com/folke/snacks.nvim) (for picker)
- [toggleterm](https://github.com/akinsho/toggleterm.nvim) (`:term` will be used otherwise)

> [!note]
> If opting not to use snacks, the standard `vim.ui.select()` function will be used
>
> If this is true, a helper plugin like dressing.nvim is recommended

# Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "paradoxical-dev/zeal.nvim",
  event = "VeryLazy",
  opts = {
    -- config here
  }
}
```

>[!note]
> If using lazy, `opts` must at least be an empty table


# Configuration

Default options:

```lua
{
  docsets_path = vim.fn.expand("~/.local/share/Zeal/Zeal/docsets"), -- zeal docset locations
  browser = { "w3m", '-o', 'display_image=FALSE' }, -- can be any terminal browser
  split = "vsplit", -- used when use_toggleterm = false
  use_toggleterm = false,
  -- toggleterm specific options
  -- see https://github.com/akinsho/toggleterm.nvim/tree/main
  toggleterm = {
  	direction = "vertical",
  	split_size = vim.o.columns * 0.5, -- when direction != float
    toggle_map = "<M-h>" -- toggle last opened zeal terem
  },
  picker = {
	type = "default", -- default | snacks
    -- snacks picker specific options.
    -- see https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
	snacks = {
	  layout = "default",
	  manager_keymaps = {
	    toggle = "<C-t>",  -- toggle between download/remove mode
	    select = "<Tab>",  -- multi-select an item
	    confirm = "<CR>",  -- confirm selection
	  },
	},
  },
  ft_map = {}
}
```

>[!tip]
> When setting the `toggle_map` option, it is necessary that the mapping also be accessible from within a terminal window

## `ft_map`

The ft_map table allows you to map certain docset names to file types. These will be passed to the `search_ft()` function or `:ZealSearchFt` command (See Usage section)

## Example Configuration

Lazy:

```lua
{
  {
  	"paradoxical-dev/zeal.nvim",
  	lazy = false,
  	keys = {
  	  {
  	  	"<leader>fd",
  	  	function()
  	  		require("zeal").search()
  	  	end,
  	  	desc = "Search Zeal docs",
  	  },
  	  {
  	  	"<leader>K",
  	  	function()
            local query = vim.fn.expand("<cword>")
  	  		require("zeal").search_ft(query)
  	  	end,
  	  	desc = "Search Zeal docs by ft for current word",
  	  },
  	},
  	opts = {
  	  browser = "w3m",
  	  use_toggleterm = true,
  	  toggleterm = {
  	  	direction = "float",
  	  },
  	  picker = {
  	  	type = "snacks",
  	  	snacks = {
  	  	  layout = "select",
  	  	},
  	  },
  	  ft_map = {
  	  	lua = { "lua_5.1" },
        js = { "javascript", "node" }
  	  },
  	},
  },
}
```

# Usage

## Commands

### `:Zeal`

Searches across all available docsets, or a specific docset if supplied as an argument.

### `:ZealToggle`

Toggles the last opened zeal terminal

### `:ZealSearchFt`

Searches docsets specified in the `ft_map` configuration option. Takes an optional `query` argument to pre filter the selection.

### `:ZealDownload`

Opens a picker to browse and download docsets from the [Zeal docset registry](https://zealdocs.org/download.html). The registry index is cached locally for 24 hours. Downloaded docsets are installed directly to `docsets_path` and can be used immediately without restarting Neovim.

> [!note]
> Docsets can also be downloaded from the Zeal GUI as usual — both sources are supported

### `:ZealRemove`

Opens a picker to select and remove an installed docset.

### `:ZealManager`

Opens a combined manager UI for downloading and removing docsets. Supports multi-select. Default keymaps: `<Tab>` to select, `<CR>` to confirm, `<C-t>` to toggle between download and remove modes. These can be customised via `picker.snacks.manager_keymaps` in your config.

## Functions

### `require("zeal").search(docset)`

Same as the `:Zeal` command

### `require("zeal").search_ft(query)`

Same as `:ZealSearchFt`

### `require("zeal.download").download()`

Same as `:ZealDownload`

### `require("zeal").remove()`

Same as `:ZealRemove`

### `require("zeal").manager()`

Same as `:ZealManager`

