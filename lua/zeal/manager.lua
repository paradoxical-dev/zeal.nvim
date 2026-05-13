local M = {}

local picker = require("zeal.picker")

--- Download a docset
---@param callback function|nil  Optional callback function
function M.download(callback)
	require("zeal.download").get_index(function(languages)
		picker.pick_download(languages, callback)
	end)
end

--- Remove a docset
---@param callback function|nil  Optional callback function
function M.remove(callback)
	local cfg = require("zeal").config
	if callback then
		picker.pick_removal(cfg, callback)
		return
	end
	picker.pick_removal(cfg)
end

function M.manager()
	picker.pick_manager()
end

return M
