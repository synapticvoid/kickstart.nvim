local M = {}

-- Insert a ROBIN code note above the current line and place the cursor after it.
function M.insert_code_note()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local current_line = vim.api.nvim_get_current_line()
  local indent = current_line:match '^%s*' or ''

  local commentstring = vim.bo.commentstring
  if commentstring == '' or not commentstring:find '%%s' then
    commentstring = '// %s'
  end

  local note = indent .. commentstring:gsub('%%s', 'ROBIN: ')

  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { note })
  vim.api.nvim_win_set_cursor(0, { row, #note })
  vim.cmd 'startinsert!'
end

vim.keymap.set('n', '<leader>cn', M.insert_code_note, { desc = '[C]ode [N]ote' })

return M
