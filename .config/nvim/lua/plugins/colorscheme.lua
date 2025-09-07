return {
  {
    "folke/tokyonight.nvim",
    lazy = false,           -- load immediately
    priority = 1000,        -- make sure it loads before all other plugins
    opts = {
      style = "moon",       -- choose: "storm", "moon", "night", "day"
      transparent = false,  -- set true if you want transparent background
      terminal_colors = true,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight") -- or tokyonight-moon / -storm / -day
    end,
  },
}
