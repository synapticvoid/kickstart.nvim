# Debugging Slidevim

## Step 1: Check Neovim
1. Open slides.md: `nvim /home/robin/teach/codingfactory/language-design-m2/slides/slides.md`
2. Did you see message "Slidevim: Started on 127.0.0.1:8765"?
3. Run `:messages` to check for errors
4. Try `:SlidevStart` manually
5. Check current slide: `:lua print(require('slidevim').get_current_slide())`

## Step 2: Check Chrome Extension
1. Open `chrome://extensions/`
2. Find "Slidevim" - is it enabled?
3. Click "Details" → "Inspect views: service worker" or check for errors
4. Open your sli.dev preview (e.g., http://localhost:3030)
5. Press F12 → Console tab
6. Look for `[Slidevim]` messages
7. Should see: `[Slidevim] Connecting to ws://localhost:8765`

## Step 3: Test WebSocket Connection
From terminal:
```bash
# Check if port 8765 is listening
ss -tlnp | grep 8765

# Test WebSocket with websocat (if installed)
# websocat ws://localhost:8765
```

## Common Issues

### "Already running" but not working
```vim
:SlidevStop
:SlidevStart
```

### Chrome can't connect
- Reload the sli.dev page (F5)
- Check Chrome console for WebSocket errors

### Slide detection wrong
```vim
:lua vim.print(require('slidevim').detect_slides())
```
