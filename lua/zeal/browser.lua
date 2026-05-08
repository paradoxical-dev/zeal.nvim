local M = {}

---@param entry table
---@param cfg table
function M.open(entry, cfg)
	if cfg.use_toggleterm then
		local Term = require("toggleterm.terminal").Terminal
		local t = Term:new({
			cmd = cfg.browser .. " '" .. entry.path .. "'",
			direction = cfg.toggleterm.direction,
		})

		t:toggle()

		if cfg.toggleterm.direction == ("vertical" or "horizontal") then
			t:resize(cfg.toggleterm.split_size)
		end
		return
	end

	vim.cmd(cfg.split)
	vim.cmd("term " .. cfg.browser .. " '" .. entry.path .. "'")
	vim.cmd("startinsert")
end

return M
