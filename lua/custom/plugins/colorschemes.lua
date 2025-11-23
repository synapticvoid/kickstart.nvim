-- Colorscheme configurations
return {
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
    end,
  },

  -- Catppuccin colorscheme (default)
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha', -- latte, frappe, macchiato, mocha
        no_italic = true, -- Disable italics
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
