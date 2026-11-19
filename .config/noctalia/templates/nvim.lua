-- Neovim colours for palettes without a scheme of their own. Noctalia renders
-- ~/.config/noctalia/templates/nvim.lua to nvim/colors/base16-noctalia.lua on
-- every palette change, so edit the template, not the output.
-- ~/.config/nvim/lua/guru/theme.lua picks this scheme and reloads it on the
-- template's SIGUSR1.
-- Adapted from Noctalia's community "neovim" template (base16-nvim plus extra
-- groups): a real colour scheme instead of lua/matugen.lua, transparent for
-- kitty, and no plugin spec or signal handler of its own.

local p = {
	surface = "{{colors.surface.default.hex}}",
	surface_container = "{{colors.surface_container.default.hex}}",
	surface_container_high = "{{colors.surface_container_high.default.hex}}",
	on_surface = "{{colors.on_surface.default.hex}}",
	on_surface_variant = "{{colors.on_surface_variant.default.hex}}",
	primary = "{{colors.primary.default.hex}}",
	primary_container = "{{colors.primary_container.default.hex}}",
	on_primary_container = "{{colors.on_primary_container.default.hex}}",
	error = "{{colors.error.default.hex}}",
	red = "{{colors.terminal_normal_red.default.hex}}",
	green = "{{colors.terminal_normal_green.default.hex}}",
	yellow = "{{colors.terminal_normal_yellow.default.hex}}",
	blue = "{{colors.terminal_normal_blue.default.hex}}",
	magenta = "{{colors.terminal_normal_magenta.default.hex}}",
	cyan = "{{colors.terminal_normal_cyan.default.hex}}",
}

-- a and b mixed in sRGB, t of the way to b. Noctalia's own blend filter
-- shifts hue instead of mixing, so the maths lives here.
local function mix(a, b, t)
	local out = "#"
	for i = 2, 6, 2 do
		local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
		out = out .. string.format("%02x", math.floor(x + (y - x) * t + 0.5))
	end
	return out
end

local function luminance(hex)
	local sum = 0
	for i, weight in ipairs({ 0.2126, 0.7152, 0.0722 }) do
		local c = tonumber(hex:sub(2 * i, 2 * i + 1), 16) / 255
		sum = sum + weight * (c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4)
	end
	return sum
end

-- The first step from bg towards fg with this WCAG contrast on bg. Palettes
-- set their outline roles very differently, so dim text is aimed by contrast.
local function readable(fg, bg, ratio)
	for t = 0.05, 1, 0.05 do
		local c = mix(bg, fg, t)
		local a, b = luminance(c), luminance(bg)
		if (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05) >= ratio then
			return c
		end
	end
	return fg
end

vim.cmd("highlight clear")
vim.o.background = "{{ mode }}"
-- The base16- prefix makes lualine's "auto" theme use its base16 theme.
vim.g.colors_name = "base16-noctalia"

local comment = readable(p.on_surface_variant, p.surface, 4.5)
local dim = readable(p.on_surface_variant, p.surface, 3) -- gutter and borders

require("base16-colorscheme").setup({
	base00 = p.surface,
	base01 = p.surface_container,
	base02 = p.surface_container_high,
	base03 = comment,
	base04 = p.on_surface_variant,
	base05 = p.on_surface,
	base06 = p.on_surface,
	base07 = p.on_surface,
	-- Syntax hues come from the terminal colours: every palette has them and,
	-- with theme.toml's terminal_colors = "standard", they keep distinct hues
	-- where the Material accents can share one.
	base08 = p.red,
	base09 = mix(p.red, p.yellow, 0.5),
	base0A = p.yellow,
	base0B = p.green,
	base0C = p.cyan,
	base0D = p.blue,
	base0E = p.magenta,
	base0F = p.on_surface_variant,
})

-- kitty is translucent: drop every background base16 painted with base00.
local base00 = tonumber(p.surface:sub(2), 16)
for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
	if hl.bg == base00 and not hl.link then
		hl.bg = nil
		vim.api.nvim_set_hl(0, name, hl)
	end
end

local function hi(group, spec)
	vim.api.nvim_set_hl(0, group, spec)
end

-- base16 colours variables red (base08), which here reads as an error.
hi("TSVariable", { fg = p.on_surface })
hi("TSVariableBuiltin", { fg = p.cyan, italic = true })
hi("Identifier", { fg = p.on_surface }) -- which-key descriptions link here
hi("TSNamespace", { fg = p.yellow })
hi("Statement", { fg = p.magenta })
hi("TSTitle", { fg = p.blue, bold = true })
hi("@keyword.return", { fg = p.magenta, italic = true })
hi("@boolean", { fg = mix(p.red, p.yellow, 0.5), bold = true })

-- Chrome from the Material roles, quieter than base16's bright base04/05.
hi("LineNr", { fg = dim })
hi("CursorLineNr", { fg = p.primary, bg = p.surface_container, bold = true })
hi("Visual", { bg = p.primary_container })
hi("FloatBorder", { fg = dim })
hi("FloatTitle", { fg = p.primary, bold = true })
hi("FzfLuaBorder", { link = "FloatBorder" }) -- fzf-lua links Normal by default
hi("FzfLuaTitle", { link = "FloatTitle" })
hi("Pmenu", { fg = p.on_surface })
hi("PmenuSel", { fg = p.on_primary_container, bg = p.primary_container, bold = true })
hi("PmenuThumb", { bg = dim })
hi("BlinkCmpMenu", { link = "Pmenu" })
hi("BlinkCmpMenuBorder", { link = "FloatBorder" })
hi("BlinkCmpMenuSelection", { link = "PmenuSel" })
hi("BlinkCmpLabelMatch", { fg = p.primary, bold = true })
hi("BlinkCmpDocBorder", { link = "FloatBorder" })
hi("BlinkCmpSignatureHelpBorder", { link = "FloatBorder" })
hi("TreesitterContext", { bg = p.surface_container })

-- base16 colours warnings like keywords; give each severity its own hue.
for severity, colour in pairs({ Error = p.error, Warn = p.yellow, Info = p.blue, Hint = p.cyan, Ok = p.green }) do
	hi("Diagnostic" .. severity, { fg = colour })
	hi("DiagnosticUnderline" .. severity, { sp = colour, undercurl = true })
end
hi("DiagnosticUnderlineWarning", { link = "DiagnosticUnderlineWarn" })
hi("DiagnosticUnderlineInformation", { link = "DiagnosticUnderlineInfo" })
hi("ErrorMsg", { fg = p.error, bold = true })
hi("WarningMsg", { fg = p.yellow, bold = true })
