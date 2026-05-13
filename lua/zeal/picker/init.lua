local docsets = require("zeal.docsets")
local M = {}

---@param entries table
---@param title string
---@param query? string
local function entry_picker(entries, title, query)
	local active_picker = require("zeal").config.picker.type
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found for " .. title, vim.log.levels.WARN)
	end

	if active_picker == "default" then
		require("zeal.picker.default").entry_picker(entries, title, query)
		return
	elseif active_picker == "snacks" then
		require("zeal.picker.snacks").entry_picker(entries, title, query)
		return
	end
end

---@param docset table
function M.pick_entry(docset)
	entry_picker(docsets.entries(docset), docset.name)
end

---@param docset_names table[]
---@param ft string
---@param query? string
function M.pick_entry_for_ft(docset_names, ft, query)
	local cfg = require("zeal").config
	local names = docsets.entries_for_ft(docset_names, cfg)
	entry_picker(names, ft, query)
end

--- Opens a picker of installed docsets and calls on_choice upon selection
---@param on_choice function  Function to call upon selection
local function pick_docsets(on_choice)
	local cfg = require("zeal").config
	local active_picker = cfg.picker.type
	local all = docsets.list(cfg)

	if #all == 0 then
		return
	end

	if #all == 1 then
		on_choice(all[1])
		return
	end

	if active_picker == "default" then
		require("zeal.picker.default").pick_docsets(all, on_choice)
		return
	elseif active_picker == "snacks" then
		require("zeal.picker.snacks").pick_docsets(all, on_choice)
		return
	end
end

--- Picks a docset to read.
function M.pick_docset()
	pick_docsets(M.pick_entry)
end

---@param languages table  Table of languages read from Zeal docset index
---@param callback function|nil  Optional callback function
function M.pick_download(languages, callback)
	local active_picker = require("zeal").config.picker.type
	if active_picker == "default" then
		require("zeal.picker.default").pick_download(languages, callback)
		return
	elseif active_picker == "snacks" then
		require("zeal.picker.snacks").pick_download(languages, callback)
	end
end

--- Performs the filesystem deletion of the docset
---@param docset table
---@param callback function?
function M.remove_docset(docset, callback)
	local ok, err = pcall(vim.fs.rm, docset.path, { recursive = true })
	if not ok then
		vim.notify("zeal.nvim: failed to remove " .. docset.name .. ": " .. err, vim.log.levels.ERROR)
		return
	end
	vim.notify("zeal.nvim: removed " .. docset.name, vim.log.levels.INFO)
	if callback then
		callback()
	end
end

--- Remove a docset
---@param callback function?
function M.pick_removal(callback)
	pick_docsets(function(docset)
		M.remove_docset(docset, callback)
	end)
end

---@param languages table?
function M.pick_manager(languages)
	local active_picker = require("zeal").config.picker.type
	if active_picker == "default" then
		require("zeal.picker.default").pick_manager()
		return
	elseif active_picker == "snacks" then
		require("zeal.picker.snacks").pick_manager(languages)
		return
	end
end

return M
