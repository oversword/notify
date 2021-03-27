
local function display_mod_name(mod_name)
	return '['..mod_name..'] '
end

local named_colors = {
	error = "#DD0000",
	warning = "#FFFF00",
	normal = "#FFFFFF"
}
named_colors.warn = named_colors.warning
named_colors.default = named_colors.normal
named_colors.err = named_colors.err

local size_chars = {
	[3] = "'",
	[4] = "fijtIl[]!:;,./\\| ",
	[5] = "r`()-{}",
	[6] = '"*',
	[8] = "cksvxyzJ1^",
	[9] = "abdeghnopquL023456789¬£$_+=~#<>?",
	[10] = "FTZ",
	[11] = "ABEKPSVXY&",
	[12] = "wCDGHNOQRU",
	[13] = "mM",
	[14] = "%",
	[15] = "W",
	[16] = "@",
}
local char_sizes = {}
for size,chars in pairs(size_chars) do
	for i=1,#chars,1 do
		local char = string.sub(chars,i,i)
		char_sizes[char] = size
	end
end
local function char_size(char)
	return char_sizes[char] or 9
end
local split_at = {
	[" "] = true,
	-- ["-"] = true
}

local function word_wrap_width(str, width)
	str = str .. " "
	local sum = 0
	local line_words = false
	local word_sum = 0
	local limited_string = ""
	local current_word = ""
	for i=1,#str,1 do
		local char = string.sub(str,i,i)
		if char == "\n" then
			limited_string = limited_string .. char
			sum = 0
			word_sum = 0
			line_words = false
			current_word = ""
		elseif split_at[char] then
			local next_sum = sum + word_sum
			if next_sum > width then
				if line_words then
					limited_string = limited_string .. "\n" .. current_word .. char
					sum = word_sum + char_size(char)
					line_words = true
				else
					limited_string = limited_string .. current_word .. "\n"
					sum = 0
					line_words = false
				end
			else
				limited_string = limited_string .. current_word .. char
				sum = next_sum + char_size(char)
				line_words = true
			end
			word_sum = 0
			current_word = ""
		else
			word_sum = word_sum + char_size(char)
			current_word = current_word .. char
		end
	end
	return limited_string
end

local methods = {
	chat = function(player, message, notifier)
		local text = string.gsub(message, "\n", '  ')
		if notifier.mod_name then
			text = display_mod_name(notifier.mod_name)..text
		end
		text = minetest.colorize(notifier.config.color or notify.settings.chat.default_color, text)
		return minetest.chat_send_player(player:get_player_name(), text)
	end,
	hud = function (player, message, notifier)
		local preface = ''
		local new_line = "\n"
		if notifier.mod_name then
			preface = display_mod_name(notifier.mod_name)
			new_line = "\n" .. preface
		end
		local text = preface .. string.gsub(message, "\n", new_line)
		return notifier.hud_notifier:notify(player, text, notifier)
	end,
	formspec = function (player, message, notifier)
		local height = 4
		local width = 6
		local text_width = (width * 50) - 30
		-- TODO: this could have more options, but unsure on the expected behaviour, it's just a nice-to-have anyways
		message = word_wrap_width(message, text_width)
		if notifier.mod_name then
			message = display_mod_name(notifier.mod_name) .. "\n" .. message
		end
		message = minetest.colorize(notifier.config.color or notify.settings.formspec.default_color, message)
		local form_spec =
			'size[' .. tostring(width) .. ',' .. tostring(height) .. ']'..
			'button_exit[' .. tostring(width - 2) .. ',' .. tostring(height - 0.8) .. ';2,1;exit;Okay]' ..
			-- 'tooltip[0,'.. tostring(offset) ..';6,4;' .. minetest.formspec_escape(message) .. ';#000000;#FFFFFF]'
			'label[0,0;' .. minetest.formspec_escape(message) .. ']'
		return minetest.show_formspec(player:get_player_name(), "notify:notification", form_spec)
	end
}


local Notifier = {}
function Notifier:new(attr)
	local config = table.copy(attr.config or {})
	if config.color and named_colors[config.color] then
		config.color = named_colors[config.color]
	end
	local o = {
		method = attr.method or 'hud',
		config = config,
		mod_name = attr.mod_name
	}
	if o.method == 'hud' then
		o.hud_notifier = attr.hud_notifier or notify.HUDNotifier:new(config)
	end
	setmetatable(o, self)
	self.__index = self
	return o
end

function Notifier:notify(player, message)
	if player == nil or message == nil then
		minetest.log('error', "Noification must be passed a player (ref or name) and a message")
		return
	end
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	return methods[self.method](player, message, self)
end

local function attrs_without_hud_notifier(notifier)
	-- local hud_notifier = notifier.hud_notifier
	-- notifier.hud_notifier = nil
	-- local attrs = table.copy(notifier)
	-- notifier.hud_notifier = hud_notifier
	-- return attrs, hud_notifier
	return table.copy({
		method = notifier.method,
		config = notifier.config,
		mod_name = notifier.mod_name
	}), notifier.hud_notifier
end

local function merge_config(base, new)
	for key,val in pairs(new) do
		if type(val) == 'table' and type(base[key]) == 'table' then
			base[key] = merge_config(base[key], val)
		else
			base[key] = val
		end
	end
	return base
end

function Notifier:notifier(config)
	local new_attrs = attrs_without_hud_notifier(self)
	new_attrs.config = merge_config(new_attrs.config, config)
	return Notifier:new(new_attrs)
end

function Notifier:mod_notifier(mod_name, config)
	local new_attrs, shared_hud_notifier = attrs_without_hud_notifier(self)
	new_attrs.mod_name = mod_name

	if config then
		new_attrs.config = merge_config(new_attrs.config, config)
	else
		new_attrs.hud_notifier = shared_hud_notifier
	end
	return Notifier:new(new_attrs)
end

Notifier.__call = function (self,...)
	return self:notify(...)
end

notify.Notifier = Notifier