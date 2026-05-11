return {
  'dhruvasagar/vim-table-mode',
  ft = 'markdown',
  init = function()
    -- Use Markdown-style pipe corners when generating/aliging tables.
    vim.g.table_mode_corner = '|'
    -- Let vim-table-mode install its buffer-local cell motions, e.g. ]|, [|, }|, {|.
    -- But avoid its default <leader>t* mappings and other surprise leader maps.
    vim.g.table_mode_map_prefix = '<Leader>m'
    vim.g.table_mode_toggle_map = 'T'
    vim.g.table_mode_realign_map = '<Leader>mR'
    vim.g.table_mode_delete_row_map = ''
    vim.g.table_mode_delete_column_map = ''
    vim.g.table_mode_insert_column_before_map = ''
    vim.g.table_mode_insert_column_after_map = ''
    vim.g.table_mode_add_formula_map = ''
    vim.g.table_mode_eval_formula_map = ''
    vim.g.table_mode_echo_cell_map = ''
    vim.g.table_mode_sort_map = ''
    vim.g.table_mode_disable_tableize_mappings = 1
  end,
  keys = {
    { '<leader>mT', '<cmd>TableModeToggle<cr>', desc = 'Markdown: Toggle table mode' },
    { '<leader>mR', '<cmd>TableModeRealign<cr>', desc = 'Markdown: Realign table' },
  },
}
