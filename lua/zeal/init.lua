local M = {}

M.default_config = {
	docsets_path = vim.fn.expand("~/.local/share/Zeal/Zeal/docsets"), -- zeal docset locations
	browser = { "w3m", "-o", "display_image=FALSE" }, -- can be any terminal browser
	split = "vsplit", -- used when use_toggleterm = false
	use_toggleterm = false,
	-- toggleterm specific options
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
			manager_keymaps = {
				toggle = "<C-t>",
				select = "<Tab>",
				confirm = "<CR>",
			},
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
		picker.pick_docset()
		return
	end

	local docset = require("zeal.docsets").find(docset_name, M.config)
	if docset then
		picker.pick_entry(docset)
	else
		vim.notify("zeal.nvim: no docset found matching '" .. docset_name .. "'", vim.log.levels.WARN)
	end
end

function M.search_ft(query)
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
	picker.pick_entry_for_ft(mapped, ft, query)
end

--- Download a docset
---@param callback function?
function M.download(callback)
	local picker = require("zeal.picker")
	require("zeal.download").get_index(function(languages)
		picker.pick_download(languages, callback)
	end)
end

--- Remove a docset
---@param callback function?
function M.remove(callback)
	local picker = require("zeal.picker")
	picker.pick_removal(callback)
end

function M.manager()
	local picker = require("zeal.picker")
	require("zeal.download").get_index(function(languages)
		picker.pick_manager(languages)
	end)
end

vim.api.nvim_create_user_command("Zeal", function(opts)
	M.search(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
	desc = "Search Zeal docsets",
})

vim.api.nvim_create_user_command("ZealSearchFt", function(opts)
	local query = opts.args ~= "" and opts.args or nil
	require("zeal").search_ft(query)
end, {
	nargs = "?",
	desc = "Search Zeal docsets for filetype",
})

vim.api.nvim_create_user_command("ZealToggle", function()
	require("zeal.browser").toggle()
end, { desc = "Toggle Zeal term" })

vim.api.nvim_create_user_command("ZealDownload", function()
	require("zeal").download()
end, { desc = "Download Zeal docsets" })

vim.api.nvim_create_user_command("ZealRemove", function()
	require("zeal").remove()
end, { desc = "Remove Zeal docsets" })

vim.api.nvim_create_user_command("ZealManager", function()
	require("zeal").manager()
end, { desc = "Open Zeal docset manager" })

return M
