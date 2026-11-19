-- One colour scheme per desktop theme; guru/theme.lua picks the active one and
-- `:colorscheme` loads only that plugin. Backgrounds stay transparent because
-- kitty is translucent.
return {
	-- ultra-dark
	{
		"vague-theme/vague.nvim",
		lazy = true,
		opts = {
			transparent = true,
			bold = true,
			italic = true,
		},
	},

	-- catppuccin-macchiato
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		opts = {
			flavour = "macchiato",
			transparent_background = true,
			-- Its completion menu is already transparent; match the floats
			-- (docs, hover, pickers) to it, as vague does.
			float = { transparent = true },
		},
	},

	-- tokyo-night
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {
			style = "night",
			transparent = true,
		},
	},

	-- Any other palette: colors/base16-noctalia.lua, which Noctalia renders
	-- from noctalia/templates/nvim.lua and which loads this on demand.
	{ "RRethy/base16-nvim", lazy = true },
}
