return {
    {
        "vague-theme/vague.nvim",
        lazy = false,
        priority = 1000,

        opts = {
            transparent = true,
            bold = true,
            italic = true,
        },

        config = function(_, opts)
            require("vague").setup(opts)
            vim.cmd.colorscheme("vague")
        end,
    },
}
