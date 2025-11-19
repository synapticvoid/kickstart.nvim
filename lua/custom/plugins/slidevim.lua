return {
  dir = vim.fn.stdpath 'config' .. '/slidevim',
  name = 'slidevim',
  ft = 'markdown',
  config = function()
    require('slidevim').config.autosave = true
  end,
}
