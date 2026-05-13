local docsets = require("zeal.docsets")
local browser = require("zeal.browser")
local M = {}

---@param entries table
---@param title string
---@param query? string
local function entry_picker(entries, title, query)
	local cfg = require("zeal").config
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found for " .. title, vim.log.levels.WARN)
	end

	if cfg.picker.type == "default" then
		-- pre filter options since vim.ui.select doesn't support patterns
		local filtered = entries
		if query and query ~= "" then
			filtered = vim.tbl_filter(function(e)
				return e.display:lower():find(query:lower(), 1, true) ~= nil
			end, entries)
		end

		vim.ui.select(filtered, {
			prompt = "Zeal [" .. title .. "]:",
			format_item = function(e)
				return e.display
			end,
		}, function(choice)
			if choice then
				browser.open(choice, cfg)
			end
		end)
		return
	end

	local snacks = require("snacks")
	local picker_cfg = cfg.picker.snacks
	local items = {}

	for _, e in ipairs(entries) do
		table.insert(items, { text = e.display, path = e.path })
	end

	snacks.picker({
		items = items,
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal [" .. title .. "]",
		pattern = query or "",
		confirm = function(picker, choice)
			picker:close()
			browser.open(choice, cfg)
		end,
		preview = "none",
	})
end

---@param docset table
function M.pick_entry(docset)
	entry_picker(docsets.entries(docset), docset.name, query)
end

---@param docset_names table[]
---@param ft string
---@param cfg table
---@param query? string
function M.pick_entry_for_ft(docset_names, ft, cfg, query)
	local names = docsets.entries_for_ft(docset_names, cfg)
	entry_picker(names, ft, query)
end

--- Opens a picker of installed docsets and calls on_choice upon selection
---@param cfg table  Config table
---@param on_choice function  Function to call upon selection
local function pick_docsets(cfg, on_choice)
	local all = docsets.list(cfg)

	if #all == 0 then
		return
	end

	if #all == 1 then
		on_choice(all[1])
		return
	end

	if cfg.picker.type == "default" then
		vim.ui.select(all, {
			prompt = "Zeal Docsets:",
			format_item = function(d)
				return d.name
			end,
		}, function(choice)
			if choice then
				on_choice(choice)
			end
		end)
		return
	end

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, d in ipairs(all) do
		table.insert(items, { text = d.name, name = d.name, path = d.path, file = d.path })
	end

	snacks.picker({
		items = items,
		format = function(d)
			return {
				{ d.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal Docsets",
		confirm = function(picker, choice)
			picker:close()
			on_choice(choice)
		end,
		preview = "none",
	})
end

--- Picks a docset to read.
function M.pick_docset(cfg)
	pick_docsets(cfg, M.pick_entry)
end

---@param languages table  Table of languages read from Zeal docset index
---@param callback function|nil  Optional callback function
function M.pick_download(languages, callback)
	local cfg = require("zeal").config
	if cfg.picker.type == "default" then
		vim.ui.select(languages, {
			prompt = "Zeal Docsets:",
			format_item = function(e)
				return e.name
			end,
		}, function(choice)
			if choice then
				require("zeal.download").download_lang(choice.name)
				if callback then
					callback(choice.name)
				end
			end
		end)
		return
	end

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, e in ipairs(languages) do
		table.insert(items, { text = e.name, name = e.name })
	end

	snacks.picker({
		items = items,
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = picker_cfg.layout,
		title = "  Zeal Docsets",
		confirm = function(picker, choice)
			picker:close()
			if choice then
				require("zeal.download").download_lang(choice.name)
				if callback then
					callback(choice.name)
				end
			end
		end,
		preview = "none",
	})
end

--- Remove a docset
---@param cfg table  Config table
---@param callback function|nil  Optional callback function
function M.pick_removal(cfg, callback)
	--- Performs the filesystem deletion of the docset
	---@param docset table
	local function remove(docset)
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
	pick_docsets(cfg, remove)
end

function M.pick_manager()
	local cfg = require("zeal").config
	if cfg.picker.type == "default" then
		vim.ui.select({ "Download", "Remove" }, {}, function(choice)
			if choice == "Download" then
				local function download_loop()
					M.download(download_loop)
				end
				download_loop()
			elseif choice == "Remove" then
				local function remove_loop()
					M.remove(remove_loop)
				end
				remove_loop()
			end
		end)
	end
end

return M
