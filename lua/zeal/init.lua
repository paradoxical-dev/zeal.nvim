local M = {}

M.default_config = {
	docsets_path = vim.fn.expand("~/.local/share/Zeal/Zeal/docsets"), -- zeal docset locations
	browser = { "w3m", '-o', 'display_image=FALSE' }, -- can be any terminal browser
	split = "vsplit", -- used when use_toggleterm = false
	use_toggleterm = false,
	-- toggleterm specifc options
	-- see https://github.com/akinsho/toggleterm.nvim/tree/main
	toggleterm = {
		direction = "vertical",
		split_size = vim.o.columns * 0.5, -- size when direction != float
		toggle_map = "<M-h>", -- toggle last opened zeal term
	},
	picker = {
		type = "default",
		snacks = {
			layout = "default",
		},
	},
	ft_map = {},
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.default_config, opts or {})

	if M.config.use_toggleterm then
		vim.api.nvim_set_keymap(
			"n",
			M.config.toggleterm.toggle_map,
			"<cmd>ZealToggle<CR>",
			{ noremap = false, silent = true }
		)
		vim.api.nvim_set_keymap(
			"t",
			M.config.toggleterm.toggle_map,
			"<cmd>ZealToggle<CR>",
			{ noremap = true, silent = true }
		)
	end
end

function M.search(docset_name)
	local picker = require("zeal.picker")

	if not docset_name then
		picker.pick_docset(M.config)
		return
	end

	local docset = require("zeal.docsets").find(docset_name, M.config)
	if docset then
		picker.pick_entry(docset, M.config)
	else
		vim.notify("zeal.nvim: no docset found matching '" .. docset_name .. "'", vim.log.levels.WARN)
	end
end

function M.search_ft()
	if not M.config.ft_map then
		vim.notify("zeal.nvim: ft_map not configured", vim.log.levels.WARN)
		return
	end

	local ft = vim.bo.filetype
	local mapped = M.config.ft_map[ft]
	if not mapped then
		vim.notify("zeal.nvim: no docsets mapped for filetype: " .. ft, vim.log.levels.WARN)
		return
	end

	local picker = require("zeal.picker")
	picker.pick_entry_for_ft(mapped, ft, M.config)
end

vim.api.nvim_create_user_command("Zeal", function(opts)
	M.search(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
	desc = "Search Zeal docsets",
})

vim.api.nvim_create_user_command("ZealToggle", function()
	require("zeal.browser").toggle()
end, { desc = "Toggle Zeal term" })

vim.api.nvim_create_user_command("ZealSearchFt", function()
	require("zeal").search_ft()
end, { desc = "Search Zeal docsets for filetype" })

return M
