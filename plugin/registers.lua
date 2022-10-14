-- This file is only for automatic detection of upgrades from 1.x versions, in future versions it will be removed

-- Prevent loading file twice
if vim.g.registers_migration_loaded then
    return
end
vim.g.registers_migration_loaded = true

-- Keep track of all settings detected and how they should be replaced
local settings_detected = {}

local function detect_config(old_name, new_type, mutate)
    local ok, var = pcall(function()
        return vim.api.nvim_get_var("registers_" .. old_name)
    end)
    -- If no var is found do nothing
    if not ok then
        return
    end

    -- Convert the var to Lua values
    if new_type == "boolean" and var == 0 then
        var = false
    elseif new_type == "boolean" and var == 1 then
        var = true
    elseif new_type == "number" then
        var = tonumber(var)
    end

    -- Create a list with the example table that will be merged
    local mergeable_config = mutate(var)
    if mergeable_config then
        settings_detected[#settings_detected + 1] = mergeable_config
    end
end

detect_config("show", "string", function(new) return { show = new } end)
detect_config("system_clip", "boolean", function(new) return { system_clipboard = new } end)
detect_config("show_empty_registers", "boolean", function(new) return { show_empty = new } end)
detect_config("trim_whitespace", "boolean", function(new) return { trim_whitespace = new } end)
detect_config("hide_only_whitespace", "boolean", function(new) return { hide_only_whitespace = new } end)
detect_config("window_border", "string", function(new) return { window = { border = new } } end)
detect_config("window_max_width", "number", function(new) return { window = { max_width = new } } end)
detect_config("tab_symbol", "string", function(new) return { symbols = { tab = new } } end)
detect_config("space_symbol", "string", function(new) return { symbols = { space = new } } end)
detect_config("return_symbol", "string", function(new) return { symbols = { newline = new } } end)
detect_config("normal_mode", "boolean", function(new)
    if new == false then
        return { bind_keys = { normal = false } }
    end
end)
detect_config("visual_mode", "boolean", function(new)
    if new == false then
        return { bind_keys = { visual = false } }
    end
end)
detect_config("insert_mode", "boolean", function(new)
    if new == false then
        return { bind_keys = { insert = false } }
    end
end)

if #settings_detected > 0 then
    -- Merge all settings into a single map
    local settings = {}
    for _, merge in ipairs(settings_detected) do
        settings = vim.tbl_extend("keep", settings, merge)
    end

    vim.notify(([[You have recently updated the plugin 'registers.nvim' to version 2.0 or later.
	This version has a new configuration mechanism using a Lua function you'll need to call manually. Previous configuration is still found. To migrate add the following to `init.vim` or `init.lua`:

	lua << EOF
	local registers = require("registers")
	registers.setup(%s)
	EOF
	]]  ):format(vim.inspect(settings)), vim.log.levels.WARN)
end
