-- TODO: settings mod? Would also decode mod.sub.var into table defs

function printTable(tab, indent)
	if not indent then indent = '' end
	if type(tab) ~= 'table' then return tostring(tab) end
	local ret = ''
	for key,value in pairs(tab) do
		ret = ret..'\n'..indent..key  .. ': ' .. printTable(value, indent..'\t') .. '; '
	end
	return '{'..ret..'\n'..string.sub(indent,2)..'}'
end

local function get_setting(name, setting_type, setting_default)
	if minetest.settings then
		-- TODO: if setting_type == 'np_group' then get_np_group
		if setting_type == 'bool' or setting_type == 'boolean' then
			return minetest.settings.get_bool(name, setting_default)
		end
		if setting_type == 'pos' or setting_type == 'position' then
			return minetest.string_to_pos(minetest.settings:get(name))
		end
		if setting_type == 'int' or setting_type == 'integer' then
			return math.floor(tonumber(minetest.settings:get(name)))
		end
		if setting_type == 'float' or setting_type == 'decimal' then
			return tonumber(minetest.settings:get(name))
		end
		return minetest.settings:get(name)
	else
		if setting_type == 'int' or setting_type == 'integer' then
			return math.floor(tonumber(minetest.setting_get(name)))
		end
		if setting_type == 'pos' or setting_type == 'position' then
			return minetest.setting_get_pos(name)
		end
		if setting_type == 'float' or setting_type == 'decimal' then
			return tonumber(minetest.setting_get(name))
		end
		if setting_type == 'bool' or setting_type == 'boolean' then
			return minetest.setting_getbool(name, setting_default)
		end
		return minetest.setting_get(name)
	end
end

local function one_of(value, values)
	for _,allowed in ipairs(values) do
		if value == allowed then
			return value
		end
	end
end

local function limit_value(value, min, max)
	return math.min(math.max(value, min), max)
end

local function limit_values(values, min, max)
	local return_values = {}
	for key,value in pairs(values) do
		return_values[key] = limit_value(value, min, max)
	end
	return return_values
end

local direction_map = {
	['left-right'] = 0,
	['right-left'] = 1,
	['top-bottom'] = 2,
	['bottom-top'] = 3
}

-- TODO: all of this could be extracted from settings.txt
notify.settings = {
	default_method = one_of(get_setting('notify.default_method'), { 'hud', 'chat', 'formspec' }) or 'hud',
	hud = {
		default_position = limit_values(
			get_setting('notify.hud.default_position', 'position') or vector.new(0.1, 0.9, 0),
		0, 1),
		default_alignment = limit_values(
			get_setting('notify.hud.default_alignment', 'position') or vector.new(1, -1, 0),
		-1, 1),
		default_offset = get_setting('notify.hud.default_offset', 'position') or vector.new(0, 0, 0),
		default_direction = direction_map[one_of(
			get_setting('notify.hud.default_direction', 'position'),
			{ 'left-right', 'right-left', 'top-bottom', 'bottom-top' }
		) or 'left-right'],
		default_duration = limit_value(get_setting('notify.hud.default_duration', 'float') or 3, 0, 1000),
		default_conflict_behaviour = one_of(
			get_setting('notify.hud.default_conflict_behaviour'),
			{'stack','stack-up','stack-down','overwrite','ignore','wait'}
		) or 'stack'
	}
}