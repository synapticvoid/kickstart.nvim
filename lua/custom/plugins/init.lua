-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  { -- Codeium
    'Exafunction/codeium.vim',
    event = 'BufEnter',
  },
  {
    'tadmccorkle/markdown.nvim',
    ft = 'markdown',
    config = function()
      require('markdown').setup()

      -- Define Lua functions to adjust heading level
      local function change_heading_level(direction)
        -- Get the current line content
        local line = vim.api.nvim_get_current_line()
        -- Pattern to match and capture the current heading symbols
        local heading_pattern = '^#+'
        local current_symbols = line:match(heading_pattern) or ''
        local new_symbols = current_symbols

        if direction == 'increase' and #current_symbols < 6 then
          -- Add one '#' to increase the level (up to H6)
          new_symbols = current_symbols .. '#'
        elseif direction == 'decrease' and #current_symbols > 0 then
          -- Remove one '#' to decrease the level
          new_symbols = current_symbols:sub(1, #current_symbols - 1)
        end

        -- If the line had a heading, replace it; otherwise, do nothing.
        if #current_symbols > 0 then
          local new_line = line:gsub(heading_pattern, new_symbols, 1)
          vim.api.nvim_set_current_line(new_line)
        end
      end

      -- Create a buffer-local autocommand to define the keymaps
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          -- INCREASE Level: <Leader>L
          vim.keymap.set('n', '<Leader>L', function()
            change_heading_level 'increase'
          end, { buffer = true, silent = true, desc = 'Markdown: Increase Heading Level' })

          -- DECREASE Level: <Leader>H
          vim.keymap.set('n', '<Leader>H', function()
            change_heading_level 'decrease'
          end, { buffer = true, silent = true, desc = 'Markdown: Decrease Heading Level' })
        end,
      })
    end,
  },
  { -- Neo-tree file explorer
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { '<leader>e', '<cmd>Neotree toggle<cr>', desc = 'Toggle file [E]xplorer' },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
      },
    },
  },
}
