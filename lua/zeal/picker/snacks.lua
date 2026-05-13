local browser = require("zeal.browser")
local docset = require("zeal.docsets")
local download = require("zeal.download")
local M = {}

local function binding_label(binding)
	if binding == " " then
		return "<Space>"
	end
	return binding
end

local keymap_action_map = {
	toggle = "toggle_mode",
	select = "select",
	confirm = "confirm",
}
local keymap_desc_map = {
	toggle = "Toggle download/remove",
	select = "Select",
	confirm = "Confirm",
}

local function build_keys(keymaps)
	local keys = {}
	for action, binding in pairs(keymaps) do
		local action_name = keymap_action_map[action]
		if not action_name then
			error("zeal.nvim: unrecognized manager keymap action: " .. tostring(action))
		end
		keys[binding] = { action_name, mode = { "n", "i" }, desc = keymap_desc_map[action] }
	end
	return keys
end

---@param entries table
---@param title string
---@param query? string
function M.entry_picker(entries, title, query)
	local snacks = require("snacks")
	local cfg = require("zeal").config
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

---@param docsets table
---@param on_choice function  Function to call upon selection
function M.pick_docsets(docsets, on_choice)
	local cfg = require("zeal").config
	local picker_cfg = cfg.picker.snacks
	local snacks = require("snacks")
	local items = {}

	for _, d in ipairs(docsets) do
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

---@param languages table  Table of languages read from Zeal docset index
---@param callback function|nil  Optional callback function
function M.pick_download(languages, callback)
	local cfg = require("zeal").config
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
				download.download_lang(choice.name)
				if callback then
					callback(choice.name)
				end
			end
		end,
		preview = "none",
	})
end

---@param languages table
function M.pick_manager(languages)
	local cfg = require("zeal").config
	local snacks = require("snacks")
	local mode = "download"

	local keys_config = cfg.picker.snacks.manager_keymaps
	local legend = {
		{
			binding_label(keys_config.confirm)
				.. " confirm  "
				.. binding_label(keys_config.select)
				.. " select  "
				.. binding_label(keys_config.toggle)
				.. " toggle",
			"Comment",
		},
	}

	local function is_meta(item)
		return item and item._kind ~= nil
	end

	local function get_title(m)
		-- to avoid whitespace being auto trimmed we need to use a special space character
		local nbsp = "\u{00A0}"
		if m == "download" then
			return {
				{ nbsp .. "Download" .. nbsp, "DiagnosticWarn" },
				{ nbsp .. "|" .. nbsp, "Comment" },
				{ "Remove" .. nbsp, "Comment" },
			}
		else
			return {
				{ nbsp .. "Download" .. nbsp, "Comment" },
				{ nbsp .. "|" .. nbsp, "Comment" },
				{ "Remove" .. nbsp, "DiagnosticWarn" },
			}
		end
	end

	local function make_download_items()
		local items = {}
		for _, e in ipairs(languages) do
			table.insert(items, { text = e.name, name = e.name })
		end
		return items
	end

	local function make_remove_items()
		local items = {}
		for _, d in ipairs(docset.list(cfg)) do
			table.insert(items, { text = d.name, name = d.name, path = d.path })
		end
		return items
	end

	local keys = build_keys(keys_config)

	snacks.picker({
		items = make_download_items(),
		format = function(e)
			return {
				{ e.text, "SnacksPickerFile" },
			}
		end,
		layout = {
			preview = false,
			layout = {
				backdrop = false,
				width = 0.5,
				min_width = 80,
				max_width = 100,
				height = 0.4,
				min_height = 2,
				box = "vertical",
				border = "rounded",
				title = "{title}",
				title_pos = "center",
				footer = legend,
				footer_pos = "center",
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "top", title = get_title(mode), title_pos = "center" },
			},
		},
		title = "  Zeal Manager",
		actions = {
			select = function(picker, item)
				if is_meta(item) then
					return
				end
				picker.list:select()
			end,
			confirm = function(picker, item)
				if is_meta(item) then
					item = nil
				end
				local selected = picker:selected()
				if #selected == 0 then
					if not item then
						return
					end
					selected = { item }
				end
				if mode == "download" then
					for _, s in ipairs(selected) do
						download.download_lang(s.name)
					end
				else
					for _, s in ipairs(selected) do
						local ok, err = pcall(vim.fs.rm, s.path, { recursive = true })
						if not ok then
							vim.notify("zeal.nvim: failed to remove " .. s.name .. ": " .. err, vim.log.levels.ERROR)
						else
							vim.notify("zeal.nvim: removed " .. s.name, vim.log.levels.INFO)
						end
					end
					picker.opts.items = make_remove_items()
					picker:find({ refresh = true })
				end
			end,
			toggle_mode = function(picker)
				picker.list:set_selected({})
				if mode == "download" then
					mode = "remove"
					picker.opts.items = make_remove_items()
				else
					mode = "download"
					picker.opts.items = make_download_items()
				end
				picker.list.win.meta.title_tpl = get_title(mode)
				picker:find({ refresh = true })
			end,
		},
		win = {
			input = { keys = keys },
			list = { keys = keys },
		},
	})
end

return M
