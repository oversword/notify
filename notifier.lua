
local function display_mod_name(mod_name)
	return '['..mod_name..'] '
end

local methods = {
	chat = function(player, message, notifier)
		local text = string.gsub(message, "\n", '  ')
		if notifier.mod_name then
			text = display_mod_name(notifier.mod_name)..text
		end
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
		-- TODO: this could have more options, but unsure on the expected behaviour, it's just a nice-to-have anyways
		local form_spec =
			'size[6,4]'..
			'button_exit[4,3.2;2,1;exit;Okay]' ..
			'label[0,0;' .. minetest.formspec_escape(message) .. ']'
		return minetest.show_formspec(player:get_player_name(), "Notification", form_spec)
	end
}


local Notifier = {}
function Notifier:new(attr)
	local o = {
		method = attr.method or 'hud',
		mod_name = nil
	}
	if o.method == 'hud' then
		o.hud_notifier = attr.hud_notifier or notify.HUDNotifier:new(attr.config or {})
	end
	setmetatable(o, self)
	self.__index = self
	return o
end

function Notifier:notify(player, message)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	return methods[self.method](player, message, self)
end

function Notifier:mod_notifier(mod_name)
	local shared_hud_notifier = self.hud_notifier
	self.hud_notifier = nil
	local new_attrs = table.copy(self)
	self.hud_notifier = shared_hud_notifier
	new_attrs.hud_notifier = shared_hud_notifier
	local notifier = Notifier:new(new_attrs)
	notifier.mod_name = mod_name
	return notifier
end

Notifier.__call = function (self,...)
	return self:notify(...)
end

notify.Notifier = Notifier