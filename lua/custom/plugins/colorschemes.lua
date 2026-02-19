-- Colorscheme configurations
return {
  { -- Nightfox colorscheme (carbonfox variant)
    'EdenEast/nightfox.nvim',
    priority = 1000,
    config = function()
      require('nightfox').setup {
        options = {
          styles = {
            comments = 'NONE',
            keywords = 'NONE',
            functions = 'NONE',
          },
        },
      }
      vim.cmd.colorscheme 'carbonfox'

      vim.keymap.set('n', '<leader>tt', function()
        local current = vim.g.colors_name
        if current == 'carbonfox' then
          vim.cmd.colorscheme 'dawnfox'
        else
          vim.cmd.colorscheme 'carbonfox'
        end
      end, { desc = '[T]oggle [T]heme' })
    end,
  },

  { -- OneDark colorscheme
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      require('onedark').setup {
        style = 'darker', -- darker, dark, cool, deep, warm, warmer, light
        code_style = {
          comments = 'none', -- Disable italics for comments
          keywords = 'none',
          functions = 'none',
          strings = 'none',
          variables = 'none',
        },
      }
      -- require('onedark').load()
    end,
  },

  { -- Tokyo Night colorscheme
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }
      -- vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Catppuccin colorscheme (default)
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        no_italic = true, -- Disable italics
      }
      -- vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
