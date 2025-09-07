return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8", -- stable release
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-h>"] = "which_key", -- show mappings
            },
          },
        },
        pickers = {
          find_files = {
            theme = "dropdown",
          },
        },
      })
      -- Keymaps
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope: Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope: Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope: Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope: Help tags" })
    end,
  },
}
