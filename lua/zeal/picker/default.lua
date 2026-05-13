local browser = require("zeal.browser")
local cfg = require("zeal").config
local M = {}

---@param entries table
---@param title string
---@param query? string
function M.entry_picker(entries, title, query)
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
end

---@param docsets table
---@param on_choice function  Function to call upon selection
function M.pick_docsets(docsets, on_choice)
	vim.ui.select(docsets, {
		prompt = "Zeal Docsets:",
		format_item = function(d)
			return d.name
		end,
	}, function(choice)
		if choice then
			on_choice(choice)
		end
	end)
end

---@param languages table  Table of languages read from Zeal docset index
---@param callback function|nil  Optional callback function
function M.pick_download(languages, callback)
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
end

function M.pick_manager()
	vim.ui.select({ "Download", "Remove" }, {}, function(choice)
		if choice == "Download" then
			local function download_loop()
				require("zeal").download(download_loop)
			end
			download_loop()
		elseif choice == "Remove" then
			local function remove_loop()
				require("zeal").remove(remove_loop)
			end
			remove_loop()
		end
	end)
end

return M
