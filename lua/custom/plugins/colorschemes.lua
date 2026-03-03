-- Colorscheme configurations
return {
  { -- Nightfox colorscheme
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
          comments = { italic = false },
        },
      }
    end,
  },

  -- Catppuccin colorscheme
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        no_italic = true,
      }
    end,
  },

  -- GitHub colorscheme
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    priority = 1000,
    config = function()
      require('github-theme').setup {
        options = {
          styles = {
            comments = 'NONE',
            keywords = 'NONE',
            functions = 'NONE',
          },
        },
      }
      vim.cmd.colorscheme 'github_dark_default'

      vim.keymap.set('n', '<leader>tt', function()
        local current = vim.g.colors_name
        if current == 'github_dark_default' then
          vim.cmd.colorscheme 'github_light'
        else
          vim.cmd.colorscheme 'github_dark_default'
        end
      end, { desc = '[T]oggle [T]heme' })
    end,
  },
}
