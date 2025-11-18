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

- **Neovim**: Detects slide boundaries by counting `---` separators (ignoring code fences and frontmatter)
- **WebSocket**: Neovim runs a server on `localhost:8765`
- **Chrome**: Content script connects and syncs navigation
- **Debouncing**: Cursor moves are debounced (400ms) to avoid spam

## Configuration

Edit `slidevim/lua/slidevim.lua`:

```lua
M.config = {
  ws_port = 8765,
  ws_host = '127.0.0.1',
  debounce_ms = 400,
  slides_dir_pattern = '/language%-design%-m2/slides/',
}
```

## Troubleshooting

**Extension not connecting:**
- Check Neovim is running and has opened a markdown file in slides directory
- Check WebSocket server started: `:SlidevStart`
- Check Chrome console (F12) for connection errors

**Wrong slide detection:**
- Ensure `---` separators are on their own line
- Code blocks with `---` inside are handled correctly
- Global frontmatter at file start is skipped automatically

**Preview not updating:**
- Check sli.dev URL format (hash vs path-based routing)
- Open Chrome DevTools console to see sync messages

## Architecture

```
Neovim (cursor move)
    ↓ detect slide #
    ↓ debounce 400ms
WebSocket Server (port 8765)
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
WebSocket Server
    ↓ jump cursor
Neovim (cursor at slide 8 start line)
```

## License

MIT
