-- Competitive Programming setup for C++
return {
	"MunifTanjim/nui.nvim", -- For floating windows (optional dependency)
	ft = { "cpp", "c" },
	config = function()
		local keymap = vim.keymap

		-- ══════════════════════════════════════════════════════════════════════
		-- COMPILE & RUN COMMANDS
		-- ══════════════════════════════════════════════════════════════════════

		-- Compile current file (optimized for CP)
		keymap.set("n", "<leader>cc", function()
			local file = vim.fn.expand("%:p")
			local out = vim.fn.expand("%:p:r")
			local cmd = string.format(
				"g++ -std=c++17 -O2 -Wall -Wextra -Wshadow -DLOCAL -o %s %s && echo '✓ Compiled successfully'",
				out,
				file
			)
			vim.cmd("w")
			vim.cmd("split | terminal " .. cmd)
		end, { desc = "CP: Compile C++ file" })

		-- Compile with debug flags
		keymap.set("n", "<leader>cd", function()
			local file = vim.fn.expand("%:p")
			local out = vim.fn.expand("%:p:r")
			local cmd = string.format(
				"g++ -std=c++17 -g -fsanitize=address,undefined -Wall -Wextra -Wshadow -DLOCAL -D_GLIBCXX_DEBUG -o %s %s && echo '✓ Compiled with debug flags'",
				out,
				file
			)
			vim.cmd("w")
			vim.cmd("split | terminal " .. cmd)
		end, { desc = "CP: Compile C++ with debug" })

		-- Run the compiled executable
		keymap.set("n", "<leader>cr", function()
			local out = vim.fn.expand("%:p:r")
			vim.cmd("split | terminal " .. out)
		end, { desc = "CP: Run executable" })

		-- Compile and run
		keymap.set("n", "<leader>cx", function()
			local file = vim.fn.expand("%:p")
			local out = vim.fn.expand("%:p:r")
			local cmd = string.format("g++ -std=c++17 -O2 -Wall -DLOCAL -o %s %s && %s", out, file, out)
			vim.cmd("w")
			vim.cmd("split | terminal " .. cmd)
		end, { desc = "CP: Compile and run" })

		-- Run with input file (expects input.txt in same directory)
		keymap.set("n", "<leader>ci", function()
			local out = vim.fn.expand("%:p:r")
			local dir = vim.fn.expand("%:p:h")
			local input_file = dir .. "/input.txt"
			if vim.fn.filereadable(input_file) == 1 then
				vim.cmd("split | terminal " .. out .. " < " .. input_file)
			else
				vim.notify("input.txt not found in " .. dir, vim.log.levels.WARN)
			end
		end, { desc = "CP: Run with input.txt" })

		-- Compile and run with input file
		keymap.set("n", "<leader>cX", function()
			local file = vim.fn.expand("%:p")
			local out = vim.fn.expand("%:p:r")
			local dir = vim.fn.expand("%:p:h")
			local input_file = dir .. "/input.txt"
			local cmd = string.format("g++ -std=c++17 -O2 -Wall -DLOCAL -o %s %s && %s < %s", out, file, out, input_file)
			vim.cmd("w")
			if vim.fn.filereadable(input_file) == 1 then
				vim.cmd("split | terminal " .. cmd)
			else
				vim.notify("input.txt not found!", vim.log.levels.WARN)
			end
		end, { desc = "CP: Compile & run with input" })

		-- ══════════════════════════════════════════════════════════════════════
		-- FILE MANAGEMENT
		-- ══════════════════════════════════════════════════════════════════════

		-- Create/open input.txt in same directory
		keymap.set("n", "<leader>ce", function()
			local dir = vim.fn.expand("%:p:h")
			vim.cmd("vsplit " .. dir .. "/input.txt")
		end, { desc = "CP: Edit input.txt" })

		-- Create new CP file from template
		keymap.set("n", "<leader>cn", function()
			vim.ui.input({ prompt = "Problem name: " }, function(name)
				if name then
					local dir = vim.fn.expand("%:p:h")
					local filepath = dir .. "/" .. name .. ".cpp"
					local template_path = vim.fn.stdpath("config") .. "/templates/cp.cpp"

					-- Check if template exists
					if vim.fn.filereadable(template_path) == 1 then
						vim.cmd("edit " .. filepath)
						vim.cmd("0r " .. template_path)
						vim.cmd("w")
					else
						vim.cmd("edit " .. filepath)
					end
				end
			end)
		end, { desc = "CP: New problem from template" })

		-- ══════════════════════════════════════════════════════════════════════
		-- QUICK SNIPPETS (Insert mode)
		-- ══════════════════════════════════════════════════════════════════════

		-- Common snippets via abbreviations
		vim.cmd([[
			augroup CPPAbbreviations
				autocmd!
				autocmd FileType cpp,c inoreabbrev <buffer> fori for (int i = 0; i < n; i++)
				autocmd FileType cpp,c inoreabbrev <buffer> forj for (int j = 0; j < m; j++)
				autocmd FileType cpp,c inoreabbrev <buffer> fork for (int k = 0; k < n; k++)
				autocmd FileType cpp,c inoreabbrev <buffer> rep for (int i = 0; i < ; i++)<Left><Left><Left><Left><Left>
				autocmd FileType cpp,c inoreabbrev <buffer> vvi vector<vector<int>>
				autocmd FileType cpp,c inoreabbrev <buffer> vi vector<int>
				autocmd FileType cpp,c inoreabbrev <buffer> vll vector<long long>
				autocmd FileType cpp,c inoreabbrev <buffer> pii pair<int, int>
				autocmd FileType cpp,c inoreabbrev <buffer> pll pair<long long, long long>
				autocmd FileType cpp,c inoreabbrev <buffer> ll long long
				autocmd FileType cpp,c inoreabbrev <buffer> ull unsigned long long
				autocmd FileType cpp,c inoreabbrev <buffer> pb push_back
				autocmd FileType cpp,c inoreabbrev <buffer> mp make_pair
				autocmd FileType cpp,c inoreabbrev <buffer> ff first
				autocmd FileType cpp,c inoreabbrev <buffer> ss second
				autocmd FileType cpp,c inoreabbrev <buffer> eb emplace_back
				autocmd FileType cpp,c inoreabbrev <buffer> sz(x) (int)(x).size()
				autocmd FileType cpp,c inoreabbrev <buffer> all(x) (x).begin(), (x).end()
				autocmd FileType cpp,c inoreabbrev <buffer> rall(x) (x).rbegin(), (x).rend()
			augroup END
		]])

		-- ══════════════════════════════════════════════════════════════════════
		-- USEFUL SETTINGS FOR CP
		-- ══════════════════════════════════════════════════════════════════════

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "cpp", "c" },
			callback = function()
				-- Faster completion
				vim.opt_local.updatetime = 100

				-- Better indentation for CP
				vim.opt_local.cindent = true
				vim.opt_local.cinoptions = "g0,N-s,t0,(0,w1,Ws"

				-- Quick comment toggle using gcc
				vim.opt_local.commentstring = "// %s"
			end,
		})

		-- Auto-close terminal on success (press any key to close)
		vim.api.nvim_create_autocmd("TermClose", {
			callback = function()
				if vim.v.event.status == 0 then
					vim.cmd("bdelete!")
				end
			end,
		})
	end,
}
