# zeal.nvim

Query and open Zeal docsets without leaving Neovim.

# Installation

## Requirements

- sqlite3
- Zeal (docsets should be downloaded from the Zeal gui)
- lynx, w3m or any other terminal browser

### Optional

- snacks.nvim (for picker)

> [!note]
> If opting not to use snacks, the standard `vim.ui.select()` function will be used
> 
> If this is true, a helper plugin like dressing.nvim is recommended
