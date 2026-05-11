local M = {}

---@param cfg table
---@return table
function M.list(cfg)
	local docsets = {}
	local handle = vim.uv.fs_scandir(cfg.docsets_path)

	if not handle then
		vim.notify("zeal.nvim: docsets path not found: " .. cfg.docsets_path, vim.log.levels.ERROR)
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
				path = cfg.docsets_path .. "/" .. name,
			})
		end
	end

	table.sort(docsets, function(a, b)
		return a.name < b.name
	end)

	return docsets
end

---@param name string
---@param cfg table
function M.find(name, cfg)
	for _, d in ipairs(M.list(cfg)) do
		if d.name:lower() == name:lower() then
			return d
		end
	end
end

---@param docset table
---@return table
function M.entries(docset)
	local db = docset.path .. "/Contents/Resources/docSet.dsidx"

	local result = vim.system({
		"sqlite3", "-json", db,
		"SELECT name, path, fragment FROM searchIndex ORDER BY name",
	}, { text = true }):wait()
	if result.code ~= 0 then
		result = vim.system({
			"sqlite3", "-json", db,
			"SELECT name, path FROM searchIndex ORDER BY name",
		}, { text = true }):wait()
		if result.code ~= 0 then
			vim.notify("zeal.nvim: sqlite error: " .. result.stderr, vim.log.levels.ERROR)
			return {}
		end
	end


	local entries = {}
	local rows = vim.json.decode(result.stdout, { luanil = { object = true, array = true } })
	for _, row in ipairs(rows) do
		-- strip path metadata?
		-- local stripped = row.path:match(">([^>]+)$") or row.path
		local stripped = row.path:match("^.*>(.+)$") or row.path
		-- local filepath = stripped:match("^([^#]+)")
		local full_path = docset.path .. "/Contents/Resources/Documents/" .. stripped
		if row.fragment and row.fragment ~= "" then
			full_path = full_path .. "#" .. row.fragment
		end

		table.insert(entries, {
			display = row.name,
			path = full_path,
		})
	end
	return entries
end

---@param docset_names table list of docset name strings
---@param cfg table
---@return table
function M.entries_for_ft(docset_names, cfg)
	local entries = {}
	for _, name in ipairs(docset_names) do
		local docset = M.find(name, cfg)

		if docset then
			for _, entry in ipairs(M.entries(docset)) do
				table.insert(entries, {
					display = "[" .. docset.name .. "] " .. entry.display,
					path = entry.path,
				})
			end
		else
			vim.notify("zeal.nvim: ft_map docset not found: " .. name, vim.log.levels.WARN)
		end
	end
	return entries
end

return M
