# Slidevim

Bidirectional sync between Neovim and sli.dev slide preview.

Move your cursor to slide 15 in Neovim → Chrome preview jumps to slide 15.  
Click slide 8 in Chrome preview → Neovim cursor jumps to slide 8.

## Installation

### Prerequisites

- [uv](https://docs.astral.sh/uv/) - Python package manager
- Chrome browser

### Chrome Extension

1. Open `chrome://extensions/` in Chrome
2. Enable "Developer mode" (top right)
3. Click "Load unpacked"
4. Select `/home/robin/.config/nvim/slidevim/chrome/`

### Neovim Plugin

Create `/home/robin/.config/nvim/lua/custom/plugins/slidevim.lua`:

```lua
return {
  dir = vim.fn.stdpath 'config' .. '/slidevim',
  name = 'slidevim',
  ft = 'markdown',
  config = function()
    require 'slidevim'
  end,
}
```

The plugin uses `uv run` which automatically handles Python dependencies (no venv needed).

## Usage

1. Start your sli.dev dev server: `npm run dev`
2. Open slides in Chrome (e.g., `http://localhost:3030`)
3. Open `slides.md` in Neovim

The plugin auto-starts when you open a markdown file in your slides directory.

### Commands

- `:SlidevStart` - Manually start WebSocket server
- `:SlidevStop` - Stop server
- `:SlidevGoto <N>` - Jump to slide N

### How it works

- **Neovim**: Detects slide boundaries by counting `---` separators, ignoring code fences, global frontmatter, and imported `src:` blocks.
- **Deck index**: Builds a global slide index from `slides.md` and imported pages, mapping each global slide to its source file and cursor line.
- **Python bridge**: `uv run slidevim/python/server.py` starts:
  - a WebSocket server for Chrome on `127.0.0.1:8765`
  - a TCP server for Neovim on `127.0.0.1:8766`
- **Chrome**: Content script connects to the WebSocket server and syncs navigation.
- **Debouncing**: Cursor moves are debounced (400ms) to avoid spam.

## Configuration

Edit `slidevim/lua/slidevim.lua`:

```lua
M.config = {
  nvim_port = 8766,
  host = '127.0.0.1',
  debounce_ms = 400,
  autosave = false,
  auto_start = true,
  slides_dir_pattern = '/slides/',
  plugin_dir = vim.fn.stdpath 'config' .. '/slidevim',
}
```

`slides_dir_pattern` is a Lua pattern matched against absolute buffer paths. The default works for decks whose root directory is named `slides`.

If you enable autosave in your lazy.nvim config:

```lua
config = function()
  require('slidevim').config.autosave = true
end
```

Slidevim only autosaves Markdown buffers matching `slides_dir_pattern`.

## Troubleshooting

**Extension not connecting:**
- Check Neovim is running and has opened a markdown file in slides directory
- Check the bridge server started: `:SlidevStart`
- Check Chrome console (F12) for connection errors
- Check ports: `ss -tlnp | grep -E '8765|8766'`

**Wrong slide detection:**
- Ensure `---` separators are on their own line
- Code blocks with `---` inside are handled correctly
- Global frontmatter at file start is skipped automatically
- Run the deck index checker:

```bash
nvim -n --headless -u NONE -c 'luafile slidevim/debug_index.lua' -c 'qa'
```

To check another deck:

```bash
SLIDEVIM_DECK_DIR=/path/to/slides \
  nvim -n --headless -u NONE -c 'luafile slidevim/debug_index.lua' -c 'qa'
```

To check the committed fixture deck:

```bash
SLIDEVIM_DECK_DIR=/home/robin/.config/nvim/slidevim/fixtures/sample-deck \
  nvim -n --headless -u NONE -c 'luafile slidevim/debug_index.lua' -c 'qa'
```

**Preview not updating:**
- Check sli.dev URL format (hash vs path-based routing)
- Open Chrome DevTools console to see sync messages

## Architecture

```
Neovim (cursor move)
    ↓ detect slide #
    ↓ debounce 400ms
Neovim TCP client (port 8766)
    ↓ {"type": "goto", "slide": 5}
Python bridge
    ↓ {"type": "goto", "slide": 5}
Chrome Extension
    ↓ update location.hash
Sli.dev Preview (navigates to slide 5)
```

Bidirectional:
```
Chrome Preview (click/navigate)
    ↓ detect hash/path change
Chrome Extension
    ↓ {"type": "navigate", "slide": 8}
Python bridge
    ↓ newline-delimited JSON over TCP
Neovim
    ↓ deck index lookup
Neovim (cursor at slide 8 source file + line)
```

## License

MIT
