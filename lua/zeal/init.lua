local M = {}

M.config = {
	docsets_path = vim.fn.expand("~/.local/share/Zeal/Zeal/docsets"),
	browser = "lynx", -- or "w3m"
	split = "vsplit", -- or "split"
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function get_docsets()
	local docsets = {}
	local handle = vim.uv.fs_scandir(M.config.docsets_path)
	if not handle then
		vim.notify("zeal.nvim: docsets path not found: " .. M.config.docsets_path, vim.log.levels.ERROR)
		return docsets
	end
	while true do
		local name, type = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if type == "directory" and name:match("%.docset$") then
			table.insert(docsets, {
				name = name:gsub("%.docset$", ""),
				path = M.config.docsets_path .. "/" .. name,
			})
		end
	end
	table.sort(docsets, function(a, b)
		return a.name < b.name
	end)
	return docsets
end

local function get_entries(docset)
	local db = docset.path .. "/Contents/Resources/docSet.dsidx"
	local raw =
		vim.fn.systemlist(string.format("sqlite3 '%s' \"SELECT name, path FROM searchIndex ORDER BY name\"", db))
	local entries = {}
	for _, line in ipairs(raw) do
		local name, path = line:match("^(.-)|(.+)$")
		if name and path then
			-- strip any anchor fragment for the file path, keep it for display
			local filepath = path:match("^([^#]+)")
			table.insert(entries, {
				display = name,
				path = docset.path .. "/Contents/Resources/Documents/" .. filepath,
			})
		end
	end
	return entries
end

local function open_entry(entry)
	vim.cmd(M.config.split)
	vim.cmd("term " .. M.config.browser .. " '" .. entry.path .. "'")
	vim.cmd("startinsert")
end

local function pick_entry(docset)
	local entries = get_entries(docset)
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found in " .. docset.name, vim.log.levels.WARN)
		return
	end
	vim.ui.select(entries, {
		prompt = "Zeal [" .. docset.name .. "]",
		format_item = function(e)
			return e.display
		end,
	}, function(choice)
		if choice then
			open_entry(choice)
		end
	end)
end

function M.search(docset_name)
	local docsets = get_docsets()
	if #docsets == 0 then
		return
	end

	if docset_name then
		for _, d in ipairs(docsets) do
			if d.name:lower() == docset_name:lower() then
				pick_entry(d)
				return
			end
		end
		vim.notify("zeal.nvim: no docset found matching '" .. docset_name .. "'", vim.log.levels.WARN)
		return
	end

	if #docsets == 1 then
		pick_entry(docsets[1])
		return
	end

	vim.ui.select(docsets, {
		prompt = "Zeal docsets",
		format_item = function(d)
			return d.name
		end,
	}, function(choice)
		if choice then
			pick_entry(choice)
		end
	end)
end

vim.api.nvim_create_user_command("Zeal", function(opts)
	require("zeal").search(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
	desc = "Search Zeal docsets",
})

return M
