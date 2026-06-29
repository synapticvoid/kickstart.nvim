# Debugging Slidevim

## 1. Check the deck index first

The committed checker validates global slide numbering and cursor target lines. It compares the current parser, the deck index, and known snapshots.

Check Robin's `language-design-m2` deck:

```bash
nvim -n --headless -u NONE -c 'luafile slidevim/debug_index.lua' -c 'qa'
```

Check the committed fixture deck:

```bash
SLIDEVIM_DECK_DIR=/home/robin/.config/nvim/slidevim/fixtures/sample-deck \
  nvim -n --headless -u NONE -c 'luafile slidevim/debug_index.lua' -c 'qa'
```

Check another Slidev deck:

```bash
SLIDEVIM_DECK_DIR=/path/to/slides \
  nvim -n --headless -u NONE -c 'luafile slidevim/debug_index.lua' -c 'qa'
```

If the checker fails, fix indexing before debugging Chrome sync.

## 2. Check Neovim

1. Open a deck file, for example:

   ```bash
   nvim /home/robin/teach/coding/language-design-m2/slides/slides.md
   ```

2. Run `:messages` and look for:
   - `Slidevim: Connected to server`
   - server startup lines from `slidevim/python/server.py`

3. If it did not start automatically, run:

   ```vim
   :SlidevStart
   ```

4. Test direct Neovim navigation:

   ```vim
   :SlidevGoto 16
   ```

   In the `language-design-m2` deck this should open `pages/01_calc.md` around line 4.

## 3. Check the bridge process

Slidevim starts a Python bridge with `uv run slidevim/python/server.py`.

The bridge listens on:

- `127.0.0.1:8765` — WebSocket for Chrome
- `127.0.0.1:8766` — TCP for Neovim

From a terminal:

```bash
ss -tlnp | grep -E '8765|8766'
```

If Neovim says the server is already running but sync is broken, restart it:

```vim
:SlidevStop
:SlidevStart
```

## 4. Check Chrome

1. Open `chrome://extensions/`.
2. Confirm the unpacked `slidevim/chrome/` extension is enabled.
3. Open your Slidev preview, usually `http://localhost:3030`.
4. Open DevTools → Console.
5. Look for `[Slidevim]` logs, especially:
   - `Connecting to ws://localhost:8765`
   - `Connected`
   - `Sent to Neovim: slide N`
   - `Goto slide: N`

If Chrome cannot connect, reload the Slidev page after `:SlidevStart`.

## 5. Useful internals

The plugin exposes a small debug API at `require('slidevim')._debug`:

```vim
:lua vim.print(require('slidevim')._debug.detect_slides())
:lua vim.print(require('slidevim')._debug.build_deck_index('/path/to/slides'))
```

These are intentionally debug/internal helpers; prefer `debug_index.lua` for repeatable checks.
