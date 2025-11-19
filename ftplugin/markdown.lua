-- This file automatically runs ONLY when you open a .md file.

-- Setting common Markdown options
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.spell = true
vim.opt.spelllang = { 'en', 'fr' }

-- Better list formatting
vim.opt_local.formatoptions:append 'n' -- Recognize numbered lists
vim.opt_local.formatoptions:append 'r' -- Continue lists with <Enter>

-- Treat hyphenated words as single words for navigation
vim.opt_local.iskeyword:append '-'

-- Comment string for markdown
vim.opt_local.commentstring = '<!--%s-->'

-- Keymaps for navigating wrapped lines (a good practice for Markdown)
vim.keymap.set('n', 'j', 'gj', { buffer = true, desc = 'Move down visual line' })
vim.keymap.set('n', 'k', 'gk', { buffer = true, desc = 'Move up visual line' })

-- Shortcut: <Leader>mc (Markdown Code block)
-- Goal: Place cursor at: ```<cursor> with closing ``` below
vim.keymap.set('n', '<Leader>mc', function()
  local code_template = { '```', '```' }
  vim.api.nvim_put(code_template, 'l', true, true)
  -- Move up one line and append at the end (after the opening ```)
  vim.cmd 'normal! kA'
end, { buffer = true, silent = true, desc = 'Create code block' })

-- Shortcut: <Leader>mtb (Markdown Table)
-- Goal: Insert basic table structure
vim.keymap.set('n', '<Leader>mtb', function()
  local table_template = {
    '| Column 1 | Column 2 | Column 3 |',
    '|----------|----------|----------|',
    '|          |          |          |',
  }
  vim.api.nvim_put(table_template, 'l', true, true)
  -- Move to first cell
  vim.cmd 'normal! 2k$'
end, { buffer = true, silent = true, desc = 'Create markdown table' })

-- Shortcut: <Leader>mi (Markdown Image)
-- Goal: Insert image syntax ![alt](path)
vim.keymap.set('n', '<Leader>mi', function()
  local image_template = { '![alt text](image-path)' }
  vim.api.nvim_put(image_template, 'l', true, true)
  -- Position cursor at 'alt text'
  vim.cmd 'normal! k$F[la'
end, { buffer = true, silent = true, desc = 'Insert image' })

-- INFO: Sli.dev specific shortcuts

-- Shortcut: <Leader>mj (Markdown Jump to next slide)
-- Goal: Jump to next slide separator with wraparound
vim.keymap.set('n', '<Leader>mj', function()
  vim.fn.setreg('/', '^---$')
  vim.fn.search('^---$', 'w')
end, { buffer = true, silent = true, desc = 'Jump to next slide' })

-- Shortcut: <Leader>mk (Markdown Jump to previous slide)
-- Goal: Jump to previous slide separator with wraparound
vim.keymap.set('n', '<Leader>mk', function()
  vim.fn.setreg('/', '^---$')
  vim.fn.search('^---$', 'bw')
end, { buffer = true, silent = true, desc = 'Jump to previous slide' })

-- Shortcut: <Leader>mn (Markdown New Slide)
-- Goal: Place cursor at: # <cursor> (in Insert Mode)
vim.keymap.set('n', '<Leader>mn', function()
  -- Uses nvim_put() to insert lines reliably in Normal mode below the cursor.
  local template = { '', '---', '', '# ' }
  -- 'l': line mode, true: after current line, true: allow text to be inserted
  vim.api.nvim_put(template, 'l', true, true)

  -- Search for the '# ' line and position cursor after it
  vim.cmd 'normal! /^# $\r$'
  vim.cmd 'startinsert!'
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
