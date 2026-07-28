-- Order matters: options sets the leader keys, which must be defined before
-- lazy.nvim reads any `keys = {}` plugin spec.
require("guru.options")
require("guru.keymaps")
require("guru.autocmds")
require("guru.lazy")
