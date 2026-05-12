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

local function ensure_index(db)
	-- docsets downloaded outside of the Zeal UI (e.g. from this plugin) are
	-- missing the searchIndex table
	local has_index_res = vim.system({
		"sqlite3",
		db,
		"SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name='searchIndex'",
	}, { text = true }):wait()

	if has_index_res.code ~= 0 then
		vim.notify("zeal.nvim: sqlite error: " .. has_index_res.stderr, vim.log.levels.ERROR)
		return
	end

	if vim.trim(has_index_res.stdout) ~= "" then
		-- searchIndex table exists, nothing to do
		return
	end

	-- SQL below is based on what Zeal does, see
	-- https://github.com/zealdocs/zeal/blob/b03c28bb9be518dc432ae585beb78a3838f63d7f/src/libs/registry/docset.cpp#L621
	local create_res = vim.system({
		"sqlite3",
		db,
		"CREATE VIEW IF NOT EXISTS searchIndex AS"
			.. " SELECT ztokenname AS name, ztypename AS type, zpath AS path, zanchor AS fragment"
			.. " FROM ztoken"
			.. " INNER JOIN ztokenmetainformation ON ztoken.zmetainformation = ztokenmetainformation.z_pk"
			.. " INNER JOIN zfilepath ON ztokenmetainformation.zfile = zfilepath.z_pk"
			.. " INNER JOIN ztokentype ON ztoken.ztokentype = ztokentype.z_pk",
	}, { text = true }):wait()

	if create_res.code ~= 0 then
		vim.notify("zeal.nvim: sqlite error: " .. create_res.stderr, vim.log.levels.ERROR)
		return
	end
end

---@param docset table
---@return table
function M.entries(docset)
	local db = docset.path .. "/Contents/Resources/docSet.dsidx"
	ensure_index(db)

	local entries_res = vim.system({
		"sqlite3",
		"-json",
		db,
		"SELECT name, path, fragment FROM searchIndex ORDER BY name",
	}, { text = true }):wait()

	if entries_res.code ~= 0 then
		-- add fallback for docsets wo fragment
		entries_res = vim.system({
			"sqlite3",
			"-json",
			db,
			"SELECT name, path FROM searchIndex ORDER BY name",
		}, { text = true }):wait()

		if entries_res.code ~= 0 then
			vim.notify("zeal.nvim: sqlite error: " .. entries_res.stderr, vim.log.levels.ERROR)
			return {}
		end
	end

	local entries = {}
	local rows = vim.json.decode(entries_res.stdout, { luanil = { object = true, array = true } })

	for _, row in ipairs(rows) do
		-- strip path metadata?
		local stripped = row.path:match("^.*>(.+)$") or row.path
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
