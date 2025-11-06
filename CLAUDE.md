# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a kickstart.nvim configuration - a single-file Neovim setup designed to be a starting point for your own configuration. It's NOT a Neovim distribution, but rather a teaching tool and reference configuration.

## Key Commands

### Plugin Management (Lazy.nvim)
- `:Lazy` - View plugin status, install/update plugins
- `:Lazy update` - Update all plugins
- `q` - Close Lazy window

### LSP & Tools (Mason)
- `:Mason` - Open Mason installer UI
- `g?` - Help in Mason menu
- `:checkhealth` - Check Neovim health and diagnose issues

### Code Formatting
- `<leader>f` - Format current buffer (uses conform.nvim)
- Format on save is enabled by default (except for C/C++)
- Uses `stylua` for Lua code formatting

### File Navigation
- `<leader>e` - Toggle Neo-tree file explorer
- `<leader>sf` - Search files (Telescope)
- `<leader>sg` - Live grep search (Telescope)
- `<leader>sw` - Search current word (Telescope)
- `<leader>sr` - Resume last Telescope search
- `<leader>sn` - Search Neovim config files
- `<leader><leader>` - Find existing buffers

### LSP Keymaps (when LSP is attached)
- `grd` - Go to definition
- `grr` - Go to references
- `gri` - Go to implementation
- `grt` - Go to type definition
- `grn` - Rename symbol
- `gra` - Code action
- `grD` - Go to declaration
- `gO` - Document symbols
- `gW` - Workspace symbols
- `<leader>th` - Toggle inlay hints

### Development
- `nvim` - Start Neovim (plugins auto-install on first run)
- Neovim's help system is the first place to look: `:help` or `<space>sh` to search help

## Configuration Architecture

### Single-File Design
The entire configuration is in `init.lua` (~1035 lines). This is intentional for educational purposes - you can read every line top-to-bottom to understand what's happening.

### Plugin Management
Uses lazy.nvim as plugin manager with lazy-loading capabilities:
- Plugins are configured in the `require('lazy').setup()` call (starting at line 248)
- Each plugin can use `opts = {}` for simple setup or `config = function()` for complex configuration
- Plugins can specify loading conditions via `event`, `keys`, `cmd`, `ft`, etc.

### LSP Configuration
LSP setup uses a multi-layered approach:
1. **Mason** - Installs LSP servers, formatters, linters
2. **mason-lspconfig** - Bridges Mason with nvim-lspconfig
3. **mason-tool-installer** - Auto-installs tools defined in `ensure_installed`
4. **nvim-lspconfig** - Configures individual language servers
5. **blink.cmp** - Provides enhanced LSP capabilities for autocompletion

LSP servers are defined in the `servers` table (line 691). Currently only `lua_ls` is configured.

### Autocompletion
Uses blink.cmp (not nvim-cmp) with LuaSnip for snippets:
- Default keymap preset uses `<c-y>` to accept completion
- `<tab>`/`<s-tab>` to navigate snippet fields
- `<c-space>` to open menu or docs
- Integrates with LSP, path, snippets, and lazydev sources

### Optional Plugin Modules
Located in `lua/kickstart/plugins/`:
- `autopairs.lua` - Auto-pair brackets, quotes
- `debug.lua` - DAP debugging setup
- `gitsigns.lua` - Additional git keymaps
- `indent_line.lua` - Indentation guides
- `lint.lua` - Linting via nvim-lint
- `neo-tree.lua` - Extended file tree config

These are commented out by default (lines 994-999). Uncomment to enable.

### Custom Plugins
Place custom plugins in `lua/custom/plugins/*.lua` and enable by uncommenting line 1005.

## Important Settings

### Leader Key
- `<space>` is the leader key (must be set before plugins load)

### Visual Settings
- `vim.g.have_nerd_font = true` - Enables Nerd Font icons
- Relative line numbers enabled
- Cursorline highlighting enabled
- Sign column always visible

### Editor Behavior
- Clipboard syncs with OS (`clipboard = 'unnamedplus'`)
- Persistent undo history (`undofile = true`)
- Case-insensitive search unless uppercase present
- Confirmation dialog for unsaved changes instead of error

### Formatting (Conform.nvim)
Format on save is enabled by default except for C/C++ (line 773-786). Configured formatters are in `formatters_by_ft` table.

### Diagnostic Configuration
- Severity sorting enabled
- Errors underlined
- Virtual text shows diagnostic messages
- Floating windows have rounded borders

## File Structure

```
/home/robin/.config/nvim/
├── init.lua                 # Main config file (single file architecture)
├── lua/
│   ├── custom/plugins/      # User's custom plugins
│   └── kickstart/
│       ├── health.lua       # Health check for kickstart
│       └── plugins/         # Optional kickstart plugins
├── lazy/                    # Lazy.nvim plugin storage (gitignored)
├── mason/                   # Mason-installed tools (gitignored)
├── .stylua.toml            # Lua formatter config
└── lazy-lock.json          # Plugin version lockfile (gitignored in this repo)
```

## Stylua Configuration
Uses these settings (`.stylua.toml`):
- Column width: 160
- Indent: 2 spaces
- Quote style: Auto-prefer single quotes
- Call parentheses: None (Lua-style `func 'string'`)

## External Dependencies

Required for full functionality:
- `git`, `make`, `unzip`, C compiler (`gcc`)
- `ripgrep` (for telescope grep)
- `fd-find` (for telescope file finding)
- Clipboard tool (`xclip`/`xsel` on Linux)
- Nerd Font (optional but recommended)

## Modularization

While this configuration is single-file by design, users who want a modular structure can:
1. Split into multiple files in `lua/` directory
2. Use `require()` to load modules
3. See kickstart-modular.nvim fork for examples

The single-file approach is maintained for teaching purposes and ease of understanding.
