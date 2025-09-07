return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but nice
  },
  keys = {
    { "<leader>e", "<Cmd>Neotree toggle<CR>", desc = "Toggle Neo-tree" },
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = false,
      popup_border_style = "NC",
      enable_git_status = true,
      enable_diagnostics = true,
      window = {
        position = "left",
        width = 40,
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_default",
        filtered_items = {
          visible = true,         -- 👈 show hidden files (dotfiles)
          hide_dotfiles = false,  -- 👈 don’t hide dotfiles
          hide_gitignored = false -- 👈 don’t hide gitignored files
        },
      },
    })
  end,
}
