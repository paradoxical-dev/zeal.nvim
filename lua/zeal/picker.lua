local docsets = require("zeal.docsets")
local browser = require("zeal.browser")
local M = {}

---@param docset table
---@param cfg table
function M.pick_entry(docset, cfg)
	local entries = docsets.entries(docset)
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found in " .. docset.name, vim.log.levels.WARN)
		return
	end

	if cfg.picker.type == "default" then
		vim.ui.select(entries, {
			prompt = "Zeal [" .. docset.name .. "]:",
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

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
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
		title = " " .. docset.name .. " Entries",
		confirm = function(picker, choice)
			picker:close()
			browser.open(choice, cfg)
		end,
		preview = "none",
	})
end

---@param docset_names table list of docset name strings
---@param ft string
---@param cfg table
function M.pick_entry_for_ft(docset_names, ft, cfg)
	local entries = docsets.entries_for_ft(docset_names, cfg)
	if #entries == 0 then
		vim.notify("zeal.nvim: no entries found for filetype " .. ft, vim.log.levels.WARN)
		return
	end

	if cfg.picker.type == "default" then
		vim.ui.select(entries, {
			prompt = "Zeal [" .. ft .. "]:",
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

	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
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
		title = "  Zeal [" .. ft .. "]",
		confirm = function(picker, choice)
			picker:close()
			browser.open(choice, cfg)
		end,
		preview = "none",
	})
end

---@param cfg table
function M.pick_docset(cfg)
	local all = docsets.list(cfg)

	if #all == 0 then
		return
	end

	if #all == 1 then
		M.pick_entry(all[1], cfg)
		return
	end

	if cfg.picker.type == "default" then
		vim.ui.select(all, {
			prompt = "Zeal docsets:",
			format_item = function(d)
				return d.name
			end,
		}, function(choice)
			if choice then
				M.pick_entry(choice, cfg)
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
			M.pick_entry(choice, cfg)
		end,
		preview = "none",
	})
end

return M
