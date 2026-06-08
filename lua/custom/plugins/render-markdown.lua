return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- Use plain Markdown markers instead of circled heading numbers for readability.
    heading = {
      icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' },
    },

    -- Render tables in normal mode only so they look clean when reading
    -- but revert to raw pipes in insert mode to avoid cursor jumping.
    pipe_table = {
      enabled = true,
    },
    render_modes = { 'n', 'c' },
  },
}
