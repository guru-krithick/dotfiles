return {
	"leath-dub/snipe.nvim",
	keys = {
		{
			"<leader>'",
			function()
				local buffers = require("snipe.buffer").get_buffers()
				if #buffers > 0 then
					require("snipe").open_buffer_menu()
				end
			end,
			desc = "Open Snipe buffer menu",
		},
	},
	opts = {},
}
