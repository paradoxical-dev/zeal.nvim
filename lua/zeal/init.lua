local M = {}

M.default_config = {
	docsets_path = vim.fn.expand("~/.local/share/Zeal/Zeal/docsets"), -- zeal docset locations
	browser = "w3m", -- can be any terminal browser
	split = "vsplit", -- used when use_toggleterm = false
	use_toggleterm = false,
	-- toggleterm specifc options
	-- see https://github.com/akinsho/toggleterm.nvim/tree/main
	toggleterm = {
		direction = "vertical",
		split_size = vim.o.columns * 0.5, -- size when direction != float
	},
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.default_config, opts or {})
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

vim.api.nvim_create_user_command("Zeal", function(opts)
	M.search(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
	desc = "Search Zeal docsets",
})

return M
