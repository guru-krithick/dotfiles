-- Neovim follows the desktop theme. Noctalia records the active palette in its
-- settings; each of our themes has a colour scheme of its own, and any other
-- palette gets base16-noctalia, which Noctalia renders from its colours
-- (noctalia/templates/nvim.lua). That template's post_hook sends SIGUSR1 after
-- every palette change, so open instances switch too.

local schemes = {
	["ultra-dark"] = "vague",
	["catppuccin-macchiato"] = "catppuccin-macchiato",
	["tokyo-night"] = "tokyonight-night",
}
local generated = "base16-noctalia"

local function xdg(name, default)
	local dir = vim.env[name]
	return dir and dir:sub(1, 1) == "/" and dir or vim.fs.joinpath(vim.env.HOME, default)
end

-- String keys of the [theme] table in one of Noctalia's TOML files.
local function theme_table(path, into)
	local file = io.open(path)
	if not file then
		return into
	end
	local section
	for line in file:lines() do
		local header = line:match("^%s*%[([^%]]+)%]")
		if header then
			section = header
		elseif section == "theme" then
			local key, value = line:match('^%s*([%w_]+)%s*=%s*"([^"]*)"')
			if key then
				into[key] = value
			end
		end
	end
	file:close()
	return into
end

-- theme.toml holds the first-run default; settings.toml, the palette picked
-- since, which Noctalia saves before it renders the templates.
local function active_theme()
	local config = vim.env.NOCTALIA_CONFIG_HOME or xdg("XDG_CONFIG_HOME", ".config")
	local theme = theme_table(vim.fs.joinpath(config, "noctalia", "theme.toml"), {})
	theme_table(vim.fs.joinpath(xdg("XDG_STATE_HOME", ".local/state"), "noctalia", "settings.toml"), theme)
	return theme.source == "custom" and theme.custom_palette or nil
end

local function apply()
	local wanted = schemes[active_theme()] or generated
	-- The generated scheme keeps its name across palettes but not its colours.
	if wanted == vim.g.colors_name and wanted ~= generated then
		return
	end
	-- Before Noctalia's first render there is no base16-noctalia: use vague
	-- quietly. Any other failure is a broken install, so say so.
	for _, name in ipairs({ wanted, "vague" }) do
		local ok, err = pcall(vim.cmd.colorscheme, name)
		if ok then
			return
		elseif name ~= generated then
			vim.notify(err, vim.log.levels.WARN)
		end
	end
end

apply()

vim.api.nvim_create_autocmd("Signal", {
	group = vim.api.nvim_create_augroup("guru_theme", { clear = true }),
	pattern = "SIGUSR1",
	callback = vim.schedule_wrap(function()
		apply()
		vim.cmd("redraw!")
	end),
})
