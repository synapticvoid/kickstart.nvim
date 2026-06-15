return {
  'sphamba/smear-cursor.nvim',
  opts = {
    -- The GitHub theme's Cursor highlight is near-white, while the terminal
    -- cursor appears blue. Pin smear to GitHub's blue so movement doesn't
    -- flash white.
    cursor_color = '#58a6ff',
    cursor_color_insert_mode = '#58a6ff',
  },
}
