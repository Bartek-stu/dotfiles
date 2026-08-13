return {
-- the colorscheme should be available when starting Neovim
  {
    "folke/tokyonight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = {
      transparent = true, -- transparent main editor background
      styles = {
        -- keep sidebars and floating windows solid so popups stay readable
        sidebars = "dark",
        floats = "dark",
      },
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      -- load the colorscheme here
      vim.cmd([[colorscheme tokyonight]])
    end,
  }
}
