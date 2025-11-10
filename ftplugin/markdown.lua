-- This file automatically runs ONLY when you open a .md file.

-- Setting common Markdown options
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.spell = true

-- Keymaps for navigating wrapped lines (a good practice for Markdown)
vim.keymap.set('n', 'j', 'gj', { buffer = true, desc = 'Move down visual line' })
vim.keymap.set('n', 'k', 'gk', { buffer = true, desc = 'Move up visual line' })

-- Shortcut: <Leader>mn (Markdown New Slide)
-- Outputs: --- [new line] # <cursor>
vim.keymap.set('n', '<Leader>mn', function()
  -- o: Open new line, then write the sequence of lines and move the cursor
  vim.cmd 'normal! o\n---\n\n# '
end, { buffer = true, silent = true, desc = 'Create new generic slide' })

-- Shortcut: <Leader>mn (Markdown New Slide)
-- Goal: Place cursor at: # <cursor> (in Insert Mode)
vim.keymap.set('n', '<Leader>mn', function()
  -- Uses nvim_put() to insert lines reliably in Normal mode below the cursor.
  local template = { '', '---', '', '# ' }
  -- 'l': line mode, true: after current line, true: allow text to be inserted
  vim.api.nvim_put(template, 'l', true, true)

  -- 'kA' moves up one line, then appends to the end of the line and starts Insert mode.
  vim.cmd 'normal! kA'
end, { buffer = true, silent = true, desc = 'Create new generic slide' })

-- Shortcut: <Leader>mt (Markdown TP Slide)
-- Goal: Place cursor at: :: content ::<cursor> (in Insert Mode)
vim.keymap.set('n', '<Leader>mt', function()
  -- Template lines
  local tp_template = {
    '',
    '---',
    'layout: tp',
    '---',
    '',
    ':: content ::',
    '',
  }
  -- Insert the template lines
  vim.api.nvim_put(tp_template, 'l', true, true)
  vim.cmd 'startinsert'
end, { buffer = true, silent = true, desc = 'Create new TP-layout slide' })
